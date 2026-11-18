"""Turn RealESRGAN_x4plus.pth (RRDBNet, 23 blocks) into an ONNX file without torch.
The checkpoint is read with a locked-down unpickler: only an OrderedDict and
plain float tensors are accepted, nothing else can be constructed."""
import sys, zipfile, pickle, collections
import numpy as np
import onnx
from onnx import helper, TensorProto, numpy_helper

src, dst = sys.argv[1], sys.argv[2]
zf = zipfile.ZipFile(src)
names = zf.namelist()
pkl = [n for n in names if n.endswith('data.pkl')][0]
prefix = pkl[: -len('data.pkl')]

class Storage:
    def __init__(self, dtype, key): self.dtype, self.key = dtype, key
DT = {'FloatStorage': np.float32, 'HalfStorage': np.float16, 'DoubleStorage': np.float64, 'LongStorage': np.int64}
class StorageType:
    def __init__(self, name): self.name = name
def rebuild(storage, offset, size, stride, *rest):
    raw = np.frombuffer(zf.read(prefix + 'data/' + storage.key), dtype=storage.dtype)
    n = int(np.prod(size)) if len(size) else 1
    arr = raw[offset: offset + n].reshape(size)
    return np.ascontiguousarray(arr, dtype=np.float32)
class Safe(pickle.Unpickler):
    def find_class(self, module, name):
        if module == 'collections' and name == 'OrderedDict': return collections.OrderedDict
        if module == 'torch._utils' and name == '_rebuild_tensor_v2': return rebuild
        if module == 'torch' and name in DT: return StorageType(name)
        raise pickle.UnpicklingError(f'blocked: {module}.{name}')
    def persistent_load(self, pid):
        kind, stype, key, _loc, _n = pid
        assert kind == 'storage'
        return Storage(DT[stype.name], key)
state = Safe(zf.open(pkl)).load()
if 'params_ema' in state: state = state['params_ema']
elif 'params' in state: state = state['params']
print(len(state), 'tensors;', list(state)[:3], '...')

nodes, inits = [], []
uid = [0]
def nm(p):
    uid[0] += 1; return f'{p}_{uid[0]}'
def const(arr, p='c'):
    n = nm(p); inits.append(numpy_helper.from_array(np.asarray(arr), n)); return n
def conv(x, key):
    w, b = const(state[key + '.weight'], 'w'), const(state[key + '.bias'], 'b')
    o = nm('conv'); nodes.append(helper.make_node('Conv', [x, w, b], [o], kernel_shape=[3, 3], pads=[1, 1, 1, 1])); return o
def lrelu(x):
    o = nm('lr'); nodes.append(helper.make_node('LeakyRelu', [x], [o], alpha=0.2)); return o
def cat(xs):
    o = nm('cat'); nodes.append(helper.make_node('Concat', xs, [o], axis=1)); return o
k02 = const(np.array(0.2, dtype=np.float32), 'k')
def resadd(y, x):
    m = nm('mul'); nodes.append(helper.make_node('Mul', [y, k02], [m]))
    o = nm('add'); nodes.append(helper.make_node('Add', [m, x], [o])); return o
def rdb(x, key):
    x1 = lrelu(conv(x, key + '.conv1'))
    x2 = lrelu(conv(cat([x, x1]), key + '.conv2'))
    x3 = lrelu(conv(cat([x, x1, x2]), key + '.conv3'))
    x4 = lrelu(conv(cat([x, x1, x2, x3]), key + '.conv4'))
    x5 = conv(cat([x, x1, x2, x3, x4]), key + '.conv5')
    return resadd(x5, x)
scales = const(np.array([1, 1, 2, 2], dtype=np.float32), 's')
def up(x):
    o = nm('up'); nodes.append(helper.make_node('Resize', [x, '', scales], [o], mode='nearest', nearest_mode='floor', coordinate_transformation_mode='asymmetric')); return o

nblocks = 1 + max(int(k.split('.')[1]) for k in state if k.startswith('body.'))
feat = conv('input', 'conv_first')
h = feat
for i in range(nblocks):
    o = rdb(h, f'body.{i}.rdb1'); o = rdb(o, f'body.{i}.rdb2'); o = rdb(o, f'body.{i}.rdb3')
    h = resadd(o, h)
body = conv(h, 'conv_body')
s = nm('add'); nodes.append(helper.make_node('Add', [feat, body], [s]))
f = lrelu(conv(up(s), 'conv_up1'))
f = lrelu(conv(up(f), 'conv_up2'))
out = conv(lrelu(conv(f, 'conv_hr')), 'conv_last')
nodes.append(helper.make_node('Identity', [out], ['output']))
g = helper.make_graph(nodes, 'rrdbnet_x4',
    [helper.make_tensor_value_info('input', TensorProto.FLOAT, [1, 3, 'h', 'w'])],
    [helper.make_tensor_value_info('output', TensorProto.FLOAT, [1, 3, 'H', 'W'])], inits)
m = helper.make_model(g, opset_imports=[helper.make_opsetid('', 13)]); m.ir_version = 8
onnx.save(m, dst)
print('blocks', nblocks, '->', dst)
