/* Soft Visitors lineup: nine super-soft kawaii aliens, hand-drawn SVG for a
   light pastel board. Soft colored outlines, gentle gradients, light from the
   top-left; every id is prefixed "sft-". */
const HEART = 'M0 3.4C-1.2 2.4-4.4 .2-4.4-2.1C-4.4-3.8-3.1-4.8-1.8-4.8C-.9-4.8-.3-4.3 0-3.6C.3-4.3 .9-4.8 1.8-4.8C3.1-4.8 4.4-3.8 4.4-2.1C4.4 .2 1.2 2.4 0 3.4Z';
const rg = (id, a, b, c) => `<radialGradient id="sft-${id}" cx=".38" cy=".3" r=".85"><stop offset="0" stop-color="${a}"/><stop offset=".55" stop-color="${b}"/><stop offset="1" stop-color="${c}"/></radialGradient>`;
// big glossy kawaii eye: dark gradient, one big + one small sparkle
const eye = (x, y, rx, ry) => `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#sft-eye)"/>`
  + `<circle cx="${+(x - rx * .36).toFixed(2)}" cy="${+(y - ry * .4).toFixed(2)}" r="${+(rx * .42).toFixed(2)}" fill="#fff"/>`
  + `<circle cx="${+(x + rx * .38).toFixed(2)}" cy="${+(y + ry * .45).toFixed(2)}" r="${+(rx * .2).toFixed(2)}" fill="#fff" opacity=".9"/>`;
const blush = (x, y, rx, ry, c = '#FF8FB3', o = '.6') => `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${c}" opacity="${o}"/>`;
const INK = '#4A3366';

export default {
  key: 'softies',
  names: ['Baby Blip', 'Jelly Puff', 'Sleepy Moon', 'Marshmallow Bot', 'Cloud Kitten', 'Plush Octo', 'Pocket Saucer', 'Bubble Sprite', 'Star Pup'],
  colors: ['#7EE8B8', '#FF9CC9', '#FFE27A', '#8EC8FF', '#C7B2FF', '#FFB38A', '#7FE3E8', '#E7A6FF', '#FF8F8F'],
  defs: `<linearGradient id="sft-eye" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2A1B3E"/><stop offset=".55" stop-color="#3D2B5C"/><stop offset="1" stop-color="#7A62B0"/></linearGradient>`
    + rg('mint', '#F0FFF8', '#8EEDC2', '#55CC9C')
    + rg('pink', '#FFF0F7', '#FFA6CF', '#F27DB2')
    + rg('lemon', '#FFFDE8', '#FFE68A', '#F7C94F')
    + rg('blue', '#F4FAFF', '#9ACFFF', '#6AA8EE')
    + rg('lav', '#FAF7FF', '#CDBAFF', '#A58CF2')
    + rg('peach', '#FFF5EE', '#FFBC97', '#F7925F')
    + rg('aqua', '#F0FFFF', '#8CE8EC', '#4FC8D0')
    + rg('lilac', '#FFF4FF', '#EAB0FF', '#CD83EE')
    + rg('coral', '#FFF0EE', '#FF9A98', '#EE6A70')
    + rg('cap', '#EEF1FF', '#B2BEFF', '#8592EA')
    + `<radialGradient id="sft-heart" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#FFE3EF"/><stop offset=".5" stop-color="#FF8DBA"/><stop offset="1" stop-color="#EE5C98"/></radialGradient>`
    + `<linearGradient id="sft-rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2FFFF"/><stop offset=".45" stop-color="#A6EEF1"/><stop offset="1" stop-color="#55C6CE"/></linearGradient>`
    + `<linearGradient id="sft-beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FE3E8" stop-opacity=".55"/><stop offset="1" stop-color="#7FE3E8" stop-opacity="0"/></linearGradient>`
    + `<radialGradient id="sft-bub" cx=".44" cy=".42" r=".6"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".1"/><stop offset=".55" stop-color="#F3D8FF" stop-opacity=".55"/><stop offset="1" stop-color="#DE92F5" stop-opacity=".9"/></radialGradient>`
    + `<linearGradient id="sft-wing" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#F0D2FF"/></linearGradient>`
    + `<linearGradient id="sft-iri" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#B06FDB"/><stop offset=".5" stop-color="#D774B6"/><stop offset="1" stop-color="#8A86E0"/></linearGradient>`,
  symbols: [
    // 1. Baby Blip: chubby baby head, heart-tipped antennae, a little curl
    `<path d="M25 21Q22.5 15.5 18.5 12.5M39 21Q41.5 15.5 45.5 12.5" fill="none" stroke="#3A9476" stroke-width="4.6" stroke-linecap="round"/>`
    + `<path d="M25 21Q22.5 15.5 18.5 12.5M39 21Q41.5 15.5 45.5 12.5" fill="none" stroke="#9DEFC9" stroke-width="2.2" stroke-linecap="round"/>`
    + `<path d="${HEART}" transform="translate(17.5 11.5) rotate(-18) scale(1.08)" fill="url(#sft-heart)" stroke="#C4507F" stroke-width="1.5" stroke-linejoin="round"/>`
    + `<path d="${HEART}" transform="translate(46.5 11.5) rotate(18) scale(1.08)" fill="url(#sft-heart)" stroke="#C4507F" stroke-width="1.5" stroke-linejoin="round"/>`
    + `<path d="M32 18.5C46.5 18.5 56 27.5 56 39.5C56 51 45.5 57.5 32 57.5C18.5 57.5 8 51 8 39.5C8 27.5 17.5 18.5 32 18.5Z" fill="url(#sft-mint)" stroke="#3A9476" stroke-width="2.2"/>`
    + `<path d="M30.5 19C29.5 14.5 33.5 12.5 35.5 15C36.8 16.8 35 18.6 33.6 17.6" fill="none" stroke="#3A9476" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<ellipse cx="20.5" cy="26.5" rx="6.5" ry="3" transform="rotate(-24 20.5 26.5)" fill="#fff" opacity=".75"/><circle cx="13.6" cy="32.5" r="1.5" fill="#fff" opacity=".7"/>`
    + eye(22.5, 39.5, 4.8, 5.8) + eye(41.5, 39.5, 4.8, 5.8)
    + blush(14.5, 47, 4, 2.4) + blush(49.5, 47, 4, 2.4)
    + `<path d="M28 46.5Q32 47.7 36 46.5Q35 52 32 52Q29 52 28 46.5Z" fill="#7B3D63" stroke="${INK}" stroke-width="1.4" stroke-linejoin="round"/>`
    + `<ellipse cx="32" cy="50.3" rx="2.2" ry="1.2" fill="#FF8FAE"/>`,

    // 2. Jelly Puff: wobbly jelly dome with a drip, happy squint
    `<path d="M9 46C8.5 26 18.5 11.5 32 11.5C45.5 11.5 55.5 26 55 46C55 50.5 52 53 48.5 51.5C47 51 46 52 46 53.5L46 55.5C46 59.2 40.5 59.2 40.5 55.5L40.5 54C40.5 51.5 37.5 50.5 35.5 52C33.2 53.8 29.8 53.8 27.5 52C25 50.2 22 50.2 19.5 52C17 53.8 13.5 53.5 11.5 51.5C10 50 9 48.5 9 46Z" fill="url(#sft-pink)" stroke="#C2457F" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M15.5 33C15.5 24 20.5 17.5 27.5 15.5" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".85"/><circle cx="31.5" cy="15" r="1.4" fill="#fff" opacity=".85"/>`
    + `<circle cx="47" cy="40" r="2.2" fill="#fff" opacity=".55"/><circle cx="50.3" cy="34" r="1.4" fill="#fff" opacity=".55"/><circle cx="14" cy="43" r="1.5" fill="#fff" opacity=".5"/>`
    + `<path d="M18.5 33Q23 27.5 27.5 33M36.5 33Q41 27.5 45.5 33" fill="none" stroke="${INK}" stroke-width="2.4" stroke-linecap="round"/>`
    + blush(15.5, 39, 4, 2.4, '#FF6FA0', '.55') + blush(48.5, 39, 4, 2.4, '#FF6FA0', '.55')
    + `<path d="M25.5 37Q32 38.8 38.5 37Q37.5 45.5 32 45.5Q26.5 45.5 25.5 37Z" fill="#7A2E55" stroke="${INK}" stroke-width="1.5" stroke-linejoin="round"/>`
    + `<path d="M28.3 42.6Q32 40 35.7 42.6Q34.6 45.4 32 45.4Q29.4 45.4 28.3 42.6Z" fill="#FF86AE"/>`,

    // 3. Sleepy Moon: chubby crescent in a nightcap, fast asleep
    `<path d="M34.45 13.44A23 23 0 1 0 52.65 39.99Q54.3 35.6 49.88 37.49A15 15 0 0 1 34.45 13.44Z" fill="url(#sft-lemon)" stroke="#C4922E" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<circle cx="24" cy="53" r="2.3" fill="#F1C24A" opacity=".55"/><circle cx="36.5" cy="51" r="1.6" fill="#F1C24A" opacity=".55"/><circle cx="12.5" cy="33" r="1.5" fill="#F1C24A" opacity=".5"/>`
    + `<path d="M14 21C13 12 21 5.5 31 5C40 4.5 47 8 51 13L48.5 15.5C45 12.5 40.5 11.5 36 13Z" fill="url(#sft-cap)" stroke="#5D63B5" stroke-width="2" stroke-linejoin="round"/>`
    + `<circle cx="25" cy="10.5" r="1.5" fill="#fff" opacity=".9"/><circle cx="36.5" cy="8.3" r="1.3" fill="#fff" opacity=".9"/><circle cx="43.5" cy="10.5" r="1.1" fill="#fff" opacity=".9"/>`
    + `<ellipse cx="25" cy="17.5" rx="12.6" ry="3.9" transform="rotate(-22 25 17.5)" fill="#FFFFFF" stroke="#5D63B5" stroke-width="2"/>`
    + `<circle cx="51.5" cy="15.5" r="4.3" fill="#FFFFFF" stroke="#5D63B5" stroke-width="2"/>`
    + `<path d="M13 39Q16.5 43 20 39M25 39Q28.5 43 32 39" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linecap="round"/>`
    + `<path d="M13.4 40.6l-1.6 1.4M31.6 40.6l1.6 1.4" stroke="${INK}" stroke-width="1.4" stroke-linecap="round"/>`
    + blush(12.8, 45.5, 3, 2) + blush(33, 45.5, 3, 2)
    + `<path d="M20.5 46Q22.5 48 24.5 46" fill="none" stroke="${INK}" stroke-width="1.6" stroke-linecap="round"/>`
    + `<path d="M38.5 24.5h5l-5 5h5M46.5 29.5h3.4l-3.4 3.4h3.4" fill="none" stroke="#8A7CC8" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>`,

    // 4. Marshmallow Bot: squishy robot, heart on the chest
    `<ellipse cx="25" cy="56.3" rx="5" ry="2.7" fill="#6AA8EE" stroke="#4677B8" stroke-width="2"/><ellipse cx="39" cy="56.3" rx="5" ry="2.7" fill="#6AA8EE" stroke="#4677B8" stroke-width="2"/>`
    + `<ellipse cx="15.5" cy="46" rx="4" ry="5.5" transform="rotate(25 15.5 46)" fill="url(#sft-blue)" stroke="#4677B8" stroke-width="2"/><ellipse cx="48.5" cy="46" rx="4" ry="5.5" transform="rotate(-25 48.5 46)" fill="url(#sft-blue)" stroke="#4677B8" stroke-width="2"/>`
    + `<rect x="18" y="36" width="28" height="20.5" rx="9.5" fill="url(#sft-blue)" stroke="#4677B8" stroke-width="2.2"/>`
    + `<ellipse cx="24" cy="40.5" rx="3.5" ry="1.5" fill="#fff" opacity=".75"/>`
    + `<path d="${HEART}" transform="translate(32 46.8) scale(1.2)" fill="url(#sft-heart)" stroke="#C4507F" stroke-width="1.3" stroke-linejoin="round"/>`
    + `<path d="M32 13V10" stroke="#4677B8" stroke-width="2.2" stroke-linecap="round"/><circle cx="32" cy="8" r="3" fill="url(#sft-heart)" stroke="#C4507F" stroke-width="1.5"/>`
    + `<rect x="8.5" y="20" width="6" height="11" rx="3" fill="#6AA8EE" stroke="#4677B8" stroke-width="2"/><rect x="49.5" y="20" width="6" height="11" rx="3" fill="#6AA8EE" stroke="#4677B8" stroke-width="2"/>`
    + `<rect x="12" y="12" width="40" height="27" rx="12" fill="url(#sft-blue)" stroke="#4677B8" stroke-width="2.2"/>`
    + `<rect x="17" y="17" width="30" height="17" rx="8" fill="#F8FBFF" stroke="#6E9BD6" stroke-width="1.4"/>`
    + `<path d="M17.5 15.5Q21 13.6 26 13.6" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" opacity=".85"/>`
    + eye(25, 25, 3.3, 4.1) + eye(39, 25, 3.3, 4.1)
    + blush(20.5, 30.5, 2.6, 1.5) + blush(43.5, 30.5, 2.6, 1.5)
    + `<path d="M29.8 29.8Q32 32 34.2 29.8" fill="none" stroke="${INK}" stroke-width="1.5" stroke-linecap="round"/>`,

    // 5. Cloud Kitten: fluffy cloud with kitten ears and whiskers
    `<path d="M11.5 29L12.8 11.5C13 9.6 14.6 9 16 10.2L29.5 22.5ZM52.5 29L51.2 11.5C51 9.6 49.4 9 48 10.2L34.5 22.5Z" fill="url(#sft-lav)" stroke="#7058C0" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M15.5 23.5L16.2 15L23.5 21.5ZM48.5 23.5L47.8 15L40.5 21.5Z" fill="#FFB8D6" stroke="#FFB8D6" stroke-width="1.4" stroke-linejoin="round"/>`
    + `<path d="M15 56C9.5 56 5.5 51.5 7 46.5C4.5 43.5 5 37 9.8 35.5C8.8 29.5 13.5 24.5 19.5 25.5C22 20 29 18 33 21.5C37 18 44.5 20 45.5 25.5C51.5 24.5 56 29.5 54.4 35.5C59 37 59.5 43.5 57 46.5C58.5 51.5 54.5 56 49 56C46.5 58.5 41 58.5 38.5 56.3C35.5 58.5 28.5 58.5 25.5 56.3C23 58.5 17.5 58.5 15 56Z" fill="url(#sft-lav)" stroke="#7058C0" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<ellipse cx="17" cy="31.5" rx="5" ry="2.4" transform="rotate(-30 17 31.5)" fill="#fff" opacity=".8"/><circle cx="29" cy="24" r="1.6" fill="#fff" opacity=".8"/>`
    + eye(24, 38.5, 4.2, 5) + eye(40, 38.5, 4.2, 5)
    + `<path d="M30.4 42.4h3.2L32 44.2Z" fill="#FF8FB3" stroke="#D2608E" stroke-width="1.2" stroke-linejoin="round"/>`
    + `<path d="M28.6 45.5Q30.3 48 32 45.5Q33.7 48 35.4 45.5" fill="none" stroke="${INK}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<path d="M9.5 41.5L16 42.8M10 46.5L16 45.2M54.5 41.5L48 42.8M54 46.5L48 45.2" stroke="#7058C0" stroke-width="1.4" stroke-linecap="round"/>`
    + blush(18.5, 47.5, 3.4, 2) + blush(45.5, 47.5, 3.4, 2),

    // 6. Plush Octo: round plush head, stubby tentacles curling outward
    `<path d="M18 41C16 46 13.5 49 11 50C8.5 51 7.5 48.5 9.5 47M46 41C48 46 50.5 49 53 50C55.5 51 56.5 48.5 54.5 47M25.5 44C24.5 48 23 51 22 54.5M38.5 44C39.5 48 41 51 42 54.5M32 45V54.5" fill="none" stroke="#C0623B" stroke-width="8.4" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<path d="M18 41C16 46 13.5 49 11 50C8.5 51 7.5 48.5 9.5 47M46 41C48 46 50.5 49 53 50C55.5 51 56.5 48.5 54.5 47M25.5 44C24.5 48 23 51 22 54.5M38.5 44C39.5 48 41 51 42 54.5M32 45V54.5" fill="none" stroke="#FFB892" stroke-width="4.4" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<circle cx="12.5" cy="49.2" r="1.1" fill="#FFE6D8"/><circle cx="51.5" cy="49.2" r="1.1" fill="#FFE6D8"/><circle cx="22.8" cy="51.5" r="1.1" fill="#FFE6D8"/><circle cx="41.2" cy="51.5" r="1.1" fill="#FFE6D8"/><circle cx="32" cy="52" r="1.1" fill="#FFE6D8"/>`
    + `<path d="M32 9C44.5 9 53 18 53 29.5C53 39.5 45 46 32 46C19 46 11 39.5 11 29.5C11 18 19.5 9 32 9Z" fill="url(#sft-peach)" stroke="#C0623B" stroke-width="2.2"/>`
    + `<ellipse cx="21.5" cy="16.5" rx="6" ry="2.8" transform="rotate(-27 21.5 16.5)" fill="#fff" opacity=".75"/>`
    + `<circle cx="44" cy="16.5" r="2.1" fill="#F28A5A" opacity=".45"/><circle cx="49" cy="23" r="1.4" fill="#F28A5A" opacity=".45"/><circle cx="39.5" cy="13" r="1.2" fill="#F28A5A" opacity=".45"/>`
    + eye(24, 29.5, 4.4, 5.2) + eye(40, 29.5, 4.4, 5.2)
    + blush(17, 36.5, 3.6, 2.2) + blush(47, 36.5, 3.6, 2.2)
    + `<path d="M29.2 36.2Q32 39.8 34.8 36.2" fill="none" stroke="${INK}" stroke-width="1.6" stroke-linecap="round"/>`,

    // 7. Pocket Saucer: tiny UFO, the dome is its happy face
    `<path d="M22.5 48.5H41.5L49 59H15Z" fill="url(#sft-beam)"/>`
    + `<ellipse cx="32" cy="48.5" rx="11" ry="3.8" fill="#55C3CB" stroke="#2A939B" stroke-width="2"/>`
    + `<path d="M15 36C15 21 22.5 11.5 32 11.5C41.5 11.5 49 21 49 36Z" fill="url(#sft-aqua)" stroke="#2A939B" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M19.5 26C20 19.5 24 15 28.5 14" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" opacity=".85"/>`
    + eye(26.5, 23.5, 3.2, 3.9) + eye(37.5, 23.5, 3.2, 3.9)
    + blush(21.5, 28.2, 2.6, 1.5) + blush(42.5, 28.2, 2.6, 1.5)
    + `<path d="M30 28Q32 30.3 34 28" fill="none" stroke="${INK}" stroke-width="1.5" stroke-linecap="round"/>`
    + `<path d="M5.5 40.5C5.5 35 17.5 32 32 32C46.5 32 58.5 35 58.5 40.5C58.5 46 46.5 49.5 32 49.5C17.5 49.5 5.5 46 5.5 40.5Z" fill="url(#sft-rim)" stroke="#2A939B" stroke-width="2.2"/>`
    + `<path d="M11 36.6Q20 34.2 30 34" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".9"/>`
    + `<circle cx="13" cy="41.5" r="2.1" fill="#FFB8D6" stroke="#2A939B" stroke-width="1.2"/><circle cx="22.5" cy="43.6" r="2.1" fill="#FFF6B8" stroke="#2A939B" stroke-width="1.2"/><circle cx="32" cy="44.3" r="2.1" fill="#FFB8D6" stroke="#2A939B" stroke-width="1.2"/><circle cx="41.5" cy="43.6" r="2.1" fill="#FFF6B8" stroke="#2A939B" stroke-width="1.2"/><circle cx="51" cy="41.5" r="2.1" fill="#FFB8D6" stroke="#2A939B" stroke-width="1.2"/>`
    + `<path d="M53 9.5Q53.6 13.4 57.5 14Q53.6 14.6 53 18.5Q52.4 14.6 48.5 14Q52.4 13.4 53 9.5Z" fill="#fff" stroke="#2A939B" stroke-width="1.3" stroke-linejoin="round"/>`,

    // 8. Bubble Sprite: little winged sprite floating in a soap bubble
    `<circle cx="32" cy="32" r="26.5" fill="url(#sft-bub)" stroke="url(#sft-iri)" stroke-width="2.4"/>`
    + `<path d="M9.6 27C11 20.5 15 15 20.5 11.8" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".95"/><circle cx="9.4" cy="32.5" r="1.4" fill="#fff"/>`
    + `<path d="M49.5 46.5C47 50 43 52.6 38.5 53.5" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity=".85"/>`
    + `<path d="M25.5 30C21 31 14.5 28.5 13.8 23.5C13.2 19.5 17 17.5 20.5 19.5C23.5 21.5 25.5 26 25.5 30ZM38.5 30C43 31 49.5 28.5 50.2 23.5C50.8 19.5 47 17.5 43.5 19.5C40.5 21.5 38.5 26 38.5 30ZM22.5 37.5C19 40 14.5 39.5 13.8 36.5C13.2 34 16 32.2 19 33C20.8 33.5 22.2 35.3 22.5 37.5ZM41.5 37.5C45 40 49.5 39.5 50.2 36.5C50.8 34 48 32.2 45 33C43.2 33.5 41.8 35.3 41.5 37.5Z" fill="url(#sft-wing)" stroke="#A86ACF" stroke-width="1.5" stroke-linejoin="round"/>`
    + `<path d="M23 27.5Q19.5 24.5 17.5 21.8M41 27.5Q44.5 24.5 46.5 21.8" fill="none" stroke="#D8B2EE" stroke-width="1.2" stroke-linecap="round"/>`
    + `<path d="M32 22Q31 17 34.5 14.5" fill="none" stroke="#9A50BC" stroke-width="1.8" stroke-linecap="round"/><circle cx="35.2" cy="13.8" r="2.5" fill="url(#sft-heart)" stroke="#9A50BC" stroke-width="1.4"/>`
    + `<circle cx="32" cy="35.5" r="13.5" fill="url(#sft-lilac)" stroke="#9A50BC" stroke-width="2"/>`
    + `<ellipse cx="26.5" cy="28" rx="4" ry="2" transform="rotate(-25 26.5 28)" fill="#fff" opacity=".8"/>`
    + eye(27, 36, 3, 3.7) + eye(37, 36, 3, 3.7)
    + blush(22.5, 41, 2.4, 1.4) + blush(41.5, 41, 2.4, 1.4)
    + `<path d="M30.2 41Q32 43 33.8 41" fill="none" stroke="${INK}" stroke-width="1.5" stroke-linecap="round"/>`,

    // 9. Star Pup: chubby star-shaped puppy with floppy ears and a tongue
    `<path d="M28.53 12.89Q32 8 35.47 12.89L39.38 18.39Q41.7 21.65 45.52 22.85L51.95 24.86Q57.68 26.66 54.1 31.47L50.08 36.89Q47.69 40.1 47.73 44.1L47.81 50.84Q47.87 56.84 42.18 54.93L35.79 52.78Q32 51.5 28.21 52.78L21.82 54.93Q16.13 56.84 16.19 50.84L16.27 44.1Q16.31 40.1 13.92 36.89L9.9 31.47Q6.32 26.66 12.05 24.86L18.48 22.85Q22.3 21.65 24.62 18.39Z" fill="url(#sft-coral)" stroke="#C1474F" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<ellipse cx="30.5" cy="15.5" rx="1.5" ry="3.2" transform="rotate(25 30.5 15.5)" fill="#fff" opacity=".75"/><ellipse cx="13" cy="27.5" rx="3" ry="1.3" transform="rotate(-15 13 27.5)" fill="#fff" opacity=".7"/>`
    + `<path d="M23.5 21.5C17.5 20.5 13.8 26.5 14.8 33.5C15.3 38 19.3 39.5 21 36.5C22.7 33.5 23.2 28.5 27 25.5C28.5 24 26.5 21.8 23.5 21.5ZM40.5 21.5C46.5 20.5 50.2 26.5 49.2 33.5C48.7 38 44.7 39.5 43 36.5C41.3 33.5 40.8 28.5 37 25.5C35.5 24 37.5 21.8 40.5 21.5Z" fill="#E8707A" stroke="#C1474F" stroke-width="1.6" stroke-linejoin="round"/>`
    + `<ellipse cx="32" cy="43.5" rx="6.8" ry="4.6" fill="#FFF1EE" opacity=".95"/>`
    + eye(25.8, 34.6, 3.9, 4.7) + eye(38.2, 34.6, 3.9, 4.7)
    + blush(20.5, 42.5, 2.8, 1.7, '#FF6F8A', '.5') + blush(43.5, 42.5, 2.8, 1.7, '#FF6F8A', '.5')
    + `<path d="M30.4 44.6C30.4 48.6 33.6 48.6 33.6 44.6Z" fill="#FF7FA0" stroke="#C1474F" stroke-width="1.2" stroke-linejoin="round"/>`
    + `<path d="M29 43.6Q30.5 45.6 32 43.6Q33.5 45.6 35 43.6" fill="none" stroke="${INK}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<ellipse cx="32" cy="41" rx="2.6" ry="1.8" fill="${INK}"/><ellipse cx="31.2" cy="40.4" rx="1" ry=".7" fill="#fff" opacity=".8"/>`,
  ],
};
