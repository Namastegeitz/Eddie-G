"""Run slow work (hashing, copying, folder scans) off the UI thread."""

from __future__ import annotations

import traceback
from typing import Any, Callable

from PySide6.QtCore import QObject, QRunnable, QThreadPool, Signal

from bml.library import ImportError_


class WorkerSignals(QObject):
    done = Signal(object)
    failed = Signal(str)
    progress = Signal(int, str)


class Worker(QRunnable):
    """Calls fn(*args, **kwargs). If fn accepts a `progress` kwarg it gets signals.progress.emit."""

    def __init__(self, fn: Callable[..., Any], *args, with_progress: bool = False, **kwargs):
        super().__init__()
        self.fn, self.args, self.kwargs = fn, args, kwargs
        self.signals = WorkerSignals()
        if with_progress:
            self.kwargs["progress"] = self.signals.progress.emit

    def run(self) -> None:
        try:
            result = self.fn(*self.args, **self.kwargs)
        except ImportError_ as e:  # expected, user-facing ("File not found", "Not an audio file")
            self.signals.failed.emit(str(e))
        except Exception as e:  # unexpected: log it and still tell the user
            traceback.print_exc()
            self.signals.failed.emit(f"{e.__class__.__name__}: {e}")
        else:
            self.signals.done.emit(result)


def start(worker: Worker) -> Worker:
    QThreadPool.globalInstance().start(worker)
    return worker
