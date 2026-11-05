/* Ancient Mysteries: carved stone & gilded metal glyphs (viewBox 0 0 64 64, light from top-left).
   Every id here starts with "anc-". */

// Left wing of the winged sun; the right wing is the same path mirrored.
const WING =
  `<path d="M28.5 18.6C21 17.2 12.5 15.6 6 15.4 4.4 16.2 4.2 18.4 5 20Q2.6 23.9 4 26.6 6.4 27.5 8.8 23.7 6.4 27.5 7.7 30.3 10.1 31.2 12.5 27.3 10.1 31.2 11.5 33.9 13.9 34.9 16.2 31 13.9 34.9 15.2 37.6 17.6 38.5 20 34.7 17.6 38.5 19 41.3 21.4 42.2 23.8 38.3 21.4 42.2 22.7 44.9 25.1 45.9 27.5 42L30 30Z" fill="url(#anc-wing)" stroke="#6b4a04" stroke-width="2.2" stroke-linejoin="round"/>` +
  `<path d="M28.5 18.6C21 17.2 12.5 15.6 6 15.4 4.4 16.2 4.2 18.4 5 20 12 20.6 20 22.6 28.8 25.6Z" fill="#fff8c8" opacity=".6"/>` +
  `<g fill="none" stroke="#b08a0c" stroke-width="1.4" stroke-linecap="round"><path d="M28.8 25.6C20 22.6 12 20.6 5 20M29.2 32C22.5 29.6 15.5 27.2 8.8 23.7"/><path d="M8.8 23.7l3.8-3.9M12.5 27.3l3.8-3.9M16.2 31l3.8-3.9M20 34.7l3.8-3.9M23.8 38.3l3.8-3.9M11 19.8l1-2.6M16 20.6l1-2.6M21 21.8l1-2.6"/></g>`;

// Rearing cobra (uraeus) hanging from the sun disk, left side.
const URAEUS =
  `<path d="M27.6 32.5C24.6 36 24.8 39.6 27.4 42 29.4 43.9 28.6 46.6 26.2 47.6" fill="none" stroke="#6b4704" stroke-width="3.8" stroke-linecap="round"/>` +
  `<path d="M27.6 32.5C24.6 36 24.8 39.6 27.4 42 29.4 43.9 28.6 46.6 26.2 47.6" fill="none" stroke="#ffd84a" stroke-width="1.8" stroke-linecap="round"/>` +
  `<ellipse cx="25.4" cy="49" rx="2.4" ry="3" fill="#ffd84a" stroke="#6b4704" stroke-width="1.3"/><circle cx="25.4" cy="48.6" r="1" fill="#3fd6c6"/>`;

export default {
  key: 'ancient',
  names: ['Great Pyramid', 'Sphinx', 'Eye of Horus', 'Ankh', 'Obelisk', 'Moai', 'Stonehenge', 'Scarab', 'Winged Sun'],
  colors: ['#F2B544', '#3F6FE0', '#3FD6C6', '#FF5A4A', '#9B7BFF', '#A3ADB8', '#FF9A3D', '#2FBF71', '#FFE45C'],
  defs:
    // 1 pyramid
    `<linearGradient id="anc-plit" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe6a8"/><stop offset=".5" stop-color="#f2b544"/><stop offset="1" stop-color="#c98a2c"/></linearGradient>` +
    `<linearGradient id="anc-pdark" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#b9772a"/><stop offset="1" stop-color="#77440f"/></linearGradient>` +
    `<linearGradient id="anc-sand" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd98a"/><stop offset="1" stop-color="#c8913a"/></linearGradient>` +
    `<linearGradient id="anc-gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff6c8"/><stop offset=".5" stop-color="#ffd24a"/><stop offset="1" stop-color="#c88a10"/></linearGradient>` +
    // 2 sphinx
    `<linearGradient id="anc-lapis" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7ea3ff"/><stop offset=".45" stop-color="#3f6fe0"/><stop offset="1" stop-color="#1c3896"/></linearGradient>` +
    `<radialGradient id="anc-face" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="#ffe6b8"/><stop offset=".5" stop-color="#e8b06c"/><stop offset="1" stop-color="#b0733a"/></radialGradient>` +
    `<linearGradient id="anc-neck" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a5226"/><stop offset="1" stop-color="#c88c50"/></linearGradient>` +
    `<clipPath id="anc-nemes"><path d="M32 4C21.5 4 15 10.5 14.3 20.5L13.6 27C11.6 35 7.8 44.5 5 52.5V58H22V40H42V58H59V52.5C56.2 44.5 52.4 35 50.4 27L49.7 20.5C49 10.5 42.5 4 32 4Z"/></clipPath>` +
    // 3 eye of horus
    `<linearGradient id="anc-turq" gradientUnits="userSpaceOnUse" x1="8" y1="8" x2="52" y2="56"><stop offset="0" stop-color="#b6fff5"/><stop offset=".45" stop-color="#3fd6c6"/><stop offset="1" stop-color="#128a80"/></linearGradient>` +
    `<radialGradient id="anc-iris" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#8ff5ea"/><stop offset=".5" stop-color="#1aa89c"/><stop offset="1" stop-color="#0b4f4a"/></radialGradient>` +
    // 4 ankh
    `<radialGradient id="anc-carn" gradientUnits="userSpaceOnUse" cx="24" cy="14" r="50"><stop offset="0" stop-color="#ffb8a4"/><stop offset=".35" stop-color="#ff5a4a"/><stop offset="1" stop-color="#9c1c10"/></radialGradient>` +
    `<linearGradient id="anc-goldu" gradientUnits="userSpaceOnUse" x1="8" y1="6" x2="56" y2="58"><stop offset="0" stop-color="#fff2b0"/><stop offset=".5" stop-color="#f5c443"/><stop offset="1" stop-color="#b7800e"/></linearGradient>` +
    // 5 obelisk
    `<linearGradient id="anc-ame" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#e6ddff"/><stop offset=".5" stop-color="#a88cff"/><stop offset="1" stop-color="#7353e6"/></linearGradient>` +
    `<linearGradient id="anc-plinth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8f78d8"/><stop offset="1" stop-color="#4b3696"/></linearGradient>` +
    // 6 moai
    `<linearGradient id="anc-moai" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#eef2f6"/><stop offset=".45" stop-color="#a3adb8"/><stop offset="1" stop-color="#58626e"/></linearGradient>` +
    // 7 stonehenge
    `<radialGradient id="anc-sun" cx=".5" cy=".55" r=".5"><stop offset="0" stop-color="#fff5c0"/><stop offset=".4" stop-color="#ffc45c"/><stop offset=".8" stop-color="#ff9a3d"/><stop offset="1" stop-color="#ee6a1e"/></radialGradient>` +
    `<linearGradient id="anc-stone" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#a99a9a"/><stop offset=".5" stop-color="#6c5c60"/><stop offset="1" stop-color="#3c3036"/></linearGradient>` +
    `<linearGradient id="anc-ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a4420"/><stop offset="1" stop-color="#3a240e"/></linearGradient>` +
    // 8 scarab
    `<radialGradient id="anc-emer" cx=".35" cy=".28" r=".85"><stop offset="0" stop-color="#b4ffd6"/><stop offset=".4" stop-color="#2fbf71"/><stop offset="1" stop-color="#0b5a30"/></radialGradient>` +
    `<radialGradient id="anc-ruby" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#ffd0a0"/><stop offset=".5" stop-color="#ff7a3a"/><stop offset="1" stop-color="#c2380e"/></radialGradient>` +
    // 9 winged sun
    `<linearGradient id="anc-wing" gradientUnits="userSpaceOnUse" x1="0" y1="15" x2="0" y2="46"><stop offset="0" stop-color="#fffbd8"/><stop offset=".45" stop-color="#ffe45c"/><stop offset="1" stop-color="#e6bd1e"/></linearGradient>` +
    `<radialGradient id="anc-disk" cx=".36" cy=".32" r=".75"><stop offset="0" stop-color="#fffdf0"/><stop offset=".45" stop-color="#ffe45c"/><stop offset="1" stop-color="#e8a412"/></radialGradient>`,
  symbols: [
    // 1 Great Pyramid
    `<path d="M32 5L40 54H4Z" fill="url(#anc-plit)"/><path d="M32 5L60 54H40Z" fill="url(#anc-pdark)"/>` +
    `<g fill="none" stroke-width="1.3" stroke-linecap="round"><path d="M26.6 14.5H33.6M22.9 21H34.6M19.1 27.5H35.7M15.4 34H36.7M11.7 40.5H37.8M8 47H38.9M28.5 14.8V21M25 21.3V27.5M31 21.3V27.5M22 27.8V34M28 27.8V34M33.5 27.8V34M18.5 34.3V40.5M25 34.3V40.5M31.5 34.3V40.5M15 40.8V47M21.5 40.8V47M28 40.8V47M34.5 40.8V47M12 47.3V53M18.5 47.3V53M25 47.3V53M31.5 47.3V53" stroke="#a96a1c" opacity=".9"/>` +
    `<path d="M33.6 14.5H37.4M34.6 21H41.1M35.7 27.5H44.9M36.7 34H48.6M37.8 40.5H52.3M38.9 47H56M38.4 21.3V27.5M41.5 27.8V34M40.5 34.3V40.5M46 34.3V40.5M43.5 40.8V47M49.5 40.8V47M46 47.3V53M53 47.3V53" stroke="#4e2a06" opacity=".75"/></g>` +
    `<path d="M32 5L40 54" stroke="#6e3e0a" stroke-width="1.4"/>` +
    `<path d="M32 5L28.3 11.5H33.1Z" fill="url(#anc-gold)"/><path d="M32 5L33.1 11.5H35.7Z" fill="#c98a10"/>` +
    `<path d="M32 5L60 54H4Z" fill="none" stroke="#5a3006" stroke-width="2.3" stroke-linejoin="round"/>` +
    `<path d="M29.4 12.5L9.5 46.5" stroke="#fff4d0" stroke-width="1.7" stroke-linecap="round" opacity=".6"/>` +
    `<path d="M4 59.5C4 55 8 52.5 14 52.5 20 52.5 24 55 32 55 40 55 45 52 52 52 57 52 60 54.5 60 59.5Z" fill="url(#anc-sand)" stroke="#6e420e" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M7.5 56C9 54.6 11.5 54 14 54" stroke="#fff6d8" stroke-width="1.4" stroke-linecap="round" opacity=".8"/>`,

    // 2 Sphinx
    `<path d="M32 4C21.5 4 15 10.5 14.3 20.5L13.6 27C11.6 35 7.8 44.5 5 52.5V58H22V40H42V58H59V52.5C56.2 44.5 52.4 35 50.4 27L49.7 20.5C49 10.5 42.5 4 32 4Z" fill="url(#anc-lapis)"/>` +
    `<g clip-path="url(#anc-nemes)" fill="none" stroke="#f7cd55" stroke-width="2.6"><path d="M0 11Q32 5 64 11M0 17Q32 11 64 17M0 23Q32 17 64 23M0 29Q32 23 64 29M0 35Q32 29 64 35M0 41Q32 35 64 41M0 47Q32 41 64 47M0 53Q32 47 64 53"/></g>` +
    `<rect x="22" y="38" width="20" height="20" fill="url(#anc-neck)"/>` +
    `<path d="M32 4C21.5 4 15 10.5 14.3 20.5L13.6 27C11.6 35 7.8 44.5 5 52.5V58H22V40H42V58H59V52.5C56.2 44.5 52.4 35 50.4 27L49.7 20.5C49 10.5 42.5 4 32 4Z" fill="none" stroke="#101c52" stroke-width="2.4" stroke-linejoin="round"/>` +
    `<ellipse cx="22.5" cy="10.5" rx="5" ry="2.2" transform="rotate(-35 22.5 10.5)" fill="#fff" opacity=".45"/>` +
    `<path d="M20 21.5C20 19.6 21.4 18.6 23.5 18.6H40.5C42.6 18.6 44 19.6 44 21.5V33C44 41.5 38.8 48 32 48 25.2 48 20 41.5 20 33Z" fill="url(#anc-face)" stroke="#5a300e" stroke-width="1.8"/>` +
    `<path d="M44 23V33C44 41.5 38.8 48 32 48 36.5 45 40 40 40.6 33V23Z" fill="#8a4a1a" opacity=".3"/>` +
    `<path d="M18.5 19.6C24 17.3 40 17.3 45.5 19.6V22.6C40 20.5 24 20.5 18.5 22.6Z" fill="#f7cd55" stroke="#6b4510" stroke-width="1.2"/>` +
    `<path d="M32 9.5C34.6 9.5 35.6 12 35.2 14.6L33.8 19.5H30.2L28.8 14.6C28.4 12 29.4 9.5 32 9.5Z" fill="#f7cd55" stroke="#6b4510" stroke-width="1.2"/><circle cx="32" cy="13.4" r="1.2" fill="#3fd6c6"/>` +
    `<g stroke="#2a1606" stroke-width="1.3" stroke-linejoin="round"><path d="M22.6 29C24.8 26.6 28 26.4 30 28.6 27.6 30.6 25 30.8 22.6 29Z" fill="#fff6e4"/><path d="M41.4 29C39.2 26.6 36 26.4 34 28.6 36.4 30.6 39 30.8 41.4 29Z" fill="#fff6e4"/></g>` +
    `<circle cx="26.6" cy="28.6" r="1.6" fill="#1d1a33"/><circle cx="37.4" cy="28.6" r="1.6" fill="#1d1a33"/>` +
    `<g fill="none" stroke-linecap="round"><path d="M22.6 29L20 30M41.4 29L44 30" stroke="#2a1606" stroke-width="1.4"/><path d="M22.4 25.2C25 23.6 28 23.6 30.4 24.9M41.6 25.2C39 23.6 36 23.6 33.6 24.9" stroke="#2b4fb0" stroke-width="1.6"/>` +
    `<path d="M32.8 29L34 37C33 38.3 31 38.3 30 37.5" stroke="#8a5426" stroke-width="1.4"/><path d="M28.4 41.6C30.6 42.6 33.4 42.6 35.6 41.6" stroke="#7a3a14" stroke-width="1.5"/></g>` +
    `<ellipse cx="24.6" cy="34.5" rx="2.6" ry="1.4" fill="#fff" opacity=".35"/>` +
    `<path d="M29 46.5H35L35.6 55.2C35.6 57 34 58 32 58 30 58 28.4 57 28.4 55.2Z" fill="#f7cd55" stroke="#6b4510" stroke-width="1.3"/><path d="M28.8 50H35.2M28.6 53.4H35.4" stroke="#2b4fb0" stroke-width="1.4"/>`,

    // 3 Eye of Horus
    `<path d="M8.5 31C17 20 33 19 44 28 33.5 39.5 18.5 40 8.5 31Z" fill="#fff1d0"/>` +
    `<circle cx="27" cy="29.6" r="6.6" fill="url(#anc-iris)"/><circle cx="27" cy="29.6" r="3" fill="#06201e"/><circle cx="25" cy="27.6" r="1.4" fill="#fff"/>` +
    `<g fill="none" stroke-linecap="round" stroke-linejoin="round">` +
    `<path d="M9 16.5C21 9.5 40 8.2 55.5 13.5M22.5 39.5V55M31.5 39C34.5 46.5 40 52.5 46.5 53 51.5 53.4 54.6 50 53.2 46.6 52 44 48.2 44.6 48.3 47.4" stroke="#0e2a28" stroke-width="9"/>` +
    `<path d="M8.5 31C17 20 33 19 44 28H55.5M8.5 31C18.5 40 33.5 39.5 44 28" stroke="#0e2a28" stroke-width="7"/>` +
    `<path d="M9 16.5C21 9.5 40 8.2 55.5 13.5M22.5 39.5V55M31.5 39C34.5 46.5 40 52.5 46.5 53 51.5 53.4 54.6 50 53.2 46.6 52 44 48.2 44.6 48.3 47.4" stroke="#f2c14e" stroke-width="7"/>` +
    `<path d="M8.5 31C17 20 33 19 44 28H55.5M8.5 31C18.5 40 33.5 39.5 44 28" stroke="#f2c14e" stroke-width="5"/>` +
    `<path d="M9 16.5C21 9.5 40 8.2 55.5 13.5M22.5 39.5V55M31.5 39C34.5 46.5 40 52.5 46.5 53 51.5 53.4 54.6 50 53.2 46.6 52 44 48.2 44.6 48.3 47.4" stroke="url(#anc-turq)" stroke-width="4.4"/>` +
    `<path d="M8.5 31C17 20 33 19 44 28H55.5M8.5 31C18.5 40 33.5 39.5 44 28" stroke="url(#anc-turq)" stroke-width="2.6"/>` +
    `<path d="M13.5 14.4C17.5 12.3 21.5 11.1 25 10.5M21.6 42.5V50" stroke="#fff" stroke-width="1.4" opacity=".75"/></g>`,

    // 4 Ankh
    `<g fill="#3d0c06" stroke="#3d0c06" stroke-width="6.6" stroke-linejoin="round"><path d="M32 7C38.3 7 43 12.5 43 19.5 43 25 40 29.5 37 32H27C24 29.5 21 25 21 19.5 21 12.5 25.7 7 32 7ZM32 12.3C28.8 12.3 26.8 15.5 26.8 19.6 26.8 23.4 29.1 26.4 32 27.8 34.9 26.4 37.2 23.4 37.2 19.6 37.2 15.5 35.2 12.3 32 12.3Z" fill-rule="evenodd"/><path d="M8.5 29C13 31 19 31.8 26 31.8H38C45 31.8 51 31 55.5 29V40.5C51 38.5 45 37.6 38 37.6H26C19 37.6 13 38.5 8.5 40.5Z"/><path d="M27 37H37C37.4 44 38.6 50.5 40.6 56.5H23.4C25.4 50.5 26.6 44 27 37Z"/></g>` +
    `<g fill="none" stroke="url(#anc-goldu)" stroke-width="4.2" stroke-linejoin="round"><path d="M32 7C38.3 7 43 12.5 43 19.5 43 25 40 29.5 37 32H27C24 29.5 21 25 21 19.5 21 12.5 25.7 7 32 7ZM32 12.3C28.8 12.3 26.8 15.5 26.8 19.6 26.8 23.4 29.1 26.4 32 27.8 34.9 26.4 37.2 23.4 37.2 19.6 37.2 15.5 35.2 12.3 32 12.3Z"/><path d="M8.5 29C13 31 19 31.8 26 31.8H38C45 31.8 51 31 55.5 29V40.5C51 38.5 45 37.6 38 37.6H26C19 37.6 13 38.5 8.5 40.5Z"/><path d="M27 37H37C37.4 44 38.6 50.5 40.6 56.5H23.4C25.4 50.5 26.6 44 27 37Z"/></g>` +
    `<g fill="url(#anc-carn)"><path d="M32 7C38.3 7 43 12.5 43 19.5 43 25 40 29.5 37 32H27C24 29.5 21 25 21 19.5 21 12.5 25.7 7 32 7ZM32 12.3C28.8 12.3 26.8 15.5 26.8 19.6 26.8 23.4 29.1 26.4 32 27.8 34.9 26.4 37.2 23.4 37.2 19.6 37.2 15.5 35.2 12.3 32 12.3Z" fill-rule="evenodd"/><path d="M8.5 29C13 31 19 31.8 26 31.8H38C45 31.8 51 31 55.5 29V40.5C51 38.5 45 37.6 38 37.6H26C19 37.6 13 38.5 8.5 40.5Z"/><path d="M27 37H37C37.4 44 38.6 50.5 40.6 56.5H23.4C25.4 50.5 26.6 44 27 37Z"/></g>` +
    `<circle cx="32" cy="34.7" r="2.6" fill="#f5c443" stroke="#7a4a06" stroke-width="1.2"/>` +
    `<g fill="none" stroke="#fff" stroke-linecap="round"><path d="M23.6 17.5C24 13 26.6 10 29.8 9.4" stroke-width="1.8" opacity=".75"/><path d="M11.5 31.6C15 32.7 19 33.3 23 33.5M29.4 41L28.4 52" stroke-width="1.5" opacity=".55"/></g>`,

    // 5 Obelisk
    `<path d="M10.5 53.5H53.5V59H10.5Z" fill="url(#anc-plinth)" stroke="#221250" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M15 49.5H49V53.5H15Z" fill="url(#anc-plinth)" stroke="#221250" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M20.5 50L25.2 15H35.4L38.2 50Z" fill="url(#anc-ame)"/><path d="M38.2 50L35.4 15H39.6L44 50Z" fill="#5232b4"/>` +
    `<path d="M25.2 15L32.4 4 35.4 15Z" fill="url(#anc-gold)"/><path d="M35.4 15L32.4 4 39.6 15Z" fill="#b57a0c"/>` +
    `<path d="M25.2 15H39.6" stroke="#7a4a06" stroke-width="1.4"/>` +
    `<g fill="none" stroke="#3a2088" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="30.2" cy="21.6" r="2.3"/><path d="M27.4 27.6H33M26.8 33.2L28.4 31.4 30 33.2 31.6 31.4 33.2 33.2M26.8 38.6Q30 36 33.2 38.6 30 41.2 26.8 38.6M30 42.6V47.6M27.8 44.4H32.2"/></g>` +
    `<path d="M38.2 50L35.4 15" stroke="#2e1a70" stroke-width="1.3"/>` +
    `<path d="M20.5 50L25.2 15 32.4 4 39.6 15 44 50Z" fill="none" stroke="#221250" stroke-width="2.2" stroke-linejoin="round"/>` +
    `<path d="M25.9 19L22.9 46M31.4 7.6L28.6 12.8" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".6"/>` +
    `<path d="M13.5 55.6H24" stroke="#d6c8ff" stroke-width="1.3" stroke-linecap="round" opacity=".7"/>`,

    // 6 Moai
    `<path d="M25 5H45C47.8 5 49.2 6.6 49.2 9.4L49.6 38C49.8 45 51 52 52.5 59H24L25 53.5C21 53.5 17.5 52.5 16.2 50 15.2 48 15.8 46.2 17 45.2 15.4 44.6 14.6 43.2 15 41.8 15.4 40.8 16.2 40.4 17 40.2L13.5 39.8C11.5 39.6 10.4 38.2 11 36.6L19.6 22C17.5 21.6 15.6 20.6 15.2 19 15 17.6 16.8 16.4 20 15.6L22.5 6.5C22.9 5.6 23.8 5 25 5Z" fill="url(#anc-moai)" stroke="#232a33" stroke-width="2.4" stroke-linejoin="round"/>` +
    `<path d="M19.6 22 13.5 39.8 17 40.2 22 39 26 30Z" fill="#7d8792" opacity=".45"/><path d="M17.4 21C21.5 22.2 26.5 22.4 31.5 20.4 30 25.6 24.5 27.4 20 25.2Z" fill="#323a44"/><path d="M15.4 43.4H22.6L25 53.4C21 53.5 17.5 52.5 16.2 50Z" fill="#7d8792" opacity=".4"/>` +
    `<path d="M37 15.5C39.5 14.8 41.5 16.3 41.5 19.5V36C41.5 39.5 39.5 41 37.5 40.3 36 39.8 35.6 38.5 35.8 36.5L36.3 19C36.3 17 36.3 15.8 37 15.5Z" fill="#8c96a2" stroke="#232a33" stroke-width="1.5"/>` +
    `<g fill="none" stroke-linecap="round"><path d="M38.8 19.5V35.5M16.4 17.2C21 15.6 27 15.4 32 16.5M20.5 26.5L16.2 35.4C17.6 37.5 19.6 38.3 21.6 38M24 52.8C30 52.8 37 50.5 42 46" stroke="#5d6773" stroke-width="1.4"/>` +
    `<path d="M13.8 38.2C15.5 38.3 16.8 37.4 17.2 36M14.8 43.4H22.5" stroke="#232a33" stroke-width="1.5"/>` +
    `<path d="M25.6 7.6H44M18.8 25L13.4 34.6M17.4 18.2C19 17.3 21 16.8 23 16.6" stroke="#fff" stroke-width="1.6" opacity=".55"/></g>` +
    `<g fill="#6a7480"><circle cx="44" cy="25" r="1.2"/><circle cx="45.5" cy="44" r="1.2"/><circle cx="30" cy="33" r="1.1"/><circle cx="41" cy="51" r="1.2"/></g>`,

    // 7 Stonehenge
    `<circle cx="32" cy="30.5" r="25.6" fill="none" stroke="#ff9a3d" stroke-width="2.4" opacity=".25"/>` +
    `<circle cx="32" cy="30.5" r="23.8" fill="url(#anc-sun)" stroke="#c4501a" stroke-width="1.6"/>` +
    `<path d="M4 51.5C16 47.6 48 47.6 60 51.5V59H4Z" fill="url(#anc-ground)" stroke="#170c04" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M5.5 50.8C18 47.6 46 47.6 58.5 50.8" fill="none" stroke="#ffb35a" stroke-width="1.5" stroke-linecap="round" opacity=".85"/>` +
    `<g fill="url(#anc-stone)" stroke="#1a1012" stroke-width="2" stroke-linejoin="round"><path d="M16.5 25.5L24.5 25 25.5 50.5 15.5 51Z"/><path d="M39.5 25L47.5 25.5 48.5 51 38.5 50.5Z"/><path d="M12.5 17.5L51.5 16.5 52 26 12 26.5Z"/></g>` +
    `<g fill="none" stroke-linecap="round"><path d="M24.6 27L25.5 50M39.4 27L38.6 50M25 25.8H39" stroke="#ffc070" stroke-width="1.5"/>` +
    `<path d="M13.8 18.8L50 17.9M17.8 27L17.2 48" stroke="#e2d2cc" stroke-width="1.3" opacity=".7"/>` +
    `<path d="M20 31L21.6 37 20.2 43M43 33L44.4 41M30 19L32.6 23.2" stroke="#2c2026" stroke-width="1.3"/></g>`,

    // 8 Scarab
    `<g fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M24 21.5L17 18 25 12.2M40 21.5L47 18 39 12.2M21 29.5L11 29 7.5 37M43 29.5L53 29 56.5 37M21 42L11.5 46.5 9.5 56M43 42L52.5 46.5 54.5 56" stroke="#07331b" stroke-width="4.6"/>` +
    `<path d="M24 21.5L17 18 25 12.2M40 21.5L47 18 39 12.2M21 29.5L11 29 7.5 37M43 29.5L53 29 56.5 37M21 42L11.5 46.5 9.5 56M43 42L52.5 46.5 54.5 56" stroke="#3ccf80" stroke-width="2.2"/></g>` +
    `<circle cx="32" cy="9.6" r="5.4" fill="url(#anc-ruby)" stroke="#5a1e06" stroke-width="1.8"/><circle cx="30.4" cy="8" r="1.4" fill="#fff" opacity=".8"/>` +
    `<path d="M32 30C42.5 30 47.5 37.5 47.5 45.5 47.5 53.5 40.5 59 32 59 23.5 59 16.5 53.5 16.5 45.5 16.5 37.5 21.5 30 32 30Z" fill="url(#anc-emer)" stroke="#07331b" stroke-width="2.2"/>` +
    `<path d="M25 21C25 18 26.5 16.2 28 15.6L29.2 14.4 30.5 15.3 32 14.2 33.5 15.3 34.8 14.4 36 15.6C37.5 16.2 39 18 39 21Z" fill="url(#anc-emer)" stroke="#07331b" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M19.5 28.5C19.5 22.5 24.5 19.5 32 19.5 39.5 19.5 44.5 22.5 44.5 28.5 44.5 31.6 42.5 33 39.5 32.5H24.5C21.5 33 19.5 31.6 19.5 28.5Z" fill="url(#anc-emer)" stroke="#07331b" stroke-width="2.2"/>` +
    `<g fill="none" stroke-linecap="round"><path d="M32 33.5V58.4" stroke="#07331b" stroke-width="1.6"/><path d="M25.5 36C23.6 41.5 23.6 49 26 55M38.5 36C40.4 41.5 40.4 49 38 55" stroke="#14804a" stroke-width="1.3"/>` +
    `<path d="M23 32.4H41" stroke="#f5c84c" stroke-width="1.4"/></g>` +
    `<g fill="#fff"><ellipse cx="25.5" cy="24.4" rx="4" ry="1.7" transform="rotate(-20 25.5 24.4)" opacity=".6"/><ellipse cx="22.6" cy="39" rx="3.2" ry="1.7" transform="rotate(-50 22.6 39)" opacity=".55"/><ellipse cx="35.6" cy="35.6" rx="2.2" ry="1.2" transform="rotate(-30 35.6 35.6)" opacity=".4"/></g>`,

    // 9 Winged Sun
    WING + `<g transform="matrix(-1 0 0 1 64 0)">${WING}</g>` +
    URAEUS + `<g transform="matrix(-1 0 0 1 64 0)">${URAEUS}</g>` +
    `<circle cx="32" cy="24" r="9.6" fill="url(#anc-disk)" stroke="#6b4704" stroke-width="2.2"/><circle cx="32" cy="24" r="6.6" fill="none" stroke="#d09412" stroke-width="1.3"/>` +
    `<ellipse cx="28.6" cy="20.6" rx="3.4" ry="1.9" transform="rotate(-35 28.6 20.6)" fill="#fff" opacity=".85"/>` +
    `<path d="M9.5 17.3C14 17.5 19 18.1 24 19" stroke="#fff" stroke-width="1.4" stroke-linecap="round" opacity=".7"/>`,
  ],
};
