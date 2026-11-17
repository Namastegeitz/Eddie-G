/* Close Encounters: glossy neon "sticker" glyphs (viewBox 0 0 64 64, light from top-left).
   Every id here starts with "enc-". */
export default {
  key: 'encounters',
  names: ['Alien Head', 'Flying Saucer', 'Tic-Tac UAP', 'Black Triangle', 'Pyramid', 'Crop Circle', 'Ray Gun', 'Cow Abduction', 'Radio Dish'],
  colors: ['#7CFF9B', '#5FD8FF', '#EAF2FF', '#B46BFF', '#FFC24A', '#D7F25A', '#FF5A5A', '#FF8FD1', '#4D8DFF'],
  defs:
    // 1 alien
    `<radialGradient id="enc-alien" cx=".36" cy=".28" r=".8"><stop offset="0" stop-color="#eafff0"/><stop offset=".42" stop-color="#8fffab"/><stop offset="1" stop-color="#25a35a"/></radialGradient>` +
    `<linearGradient id="enc-eye" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#34405e"/><stop offset=".45" stop-color="#0c1022"/><stop offset="1" stop-color="#000"/></linearGradient>` +
    // 2 saucer
    `<linearGradient id="enc-disc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#effcff"/><stop offset=".45" stop-color="#5fd8ff"/><stop offset="1" stop-color="#1773a6"/></linearGradient>` +
    `<radialGradient id="enc-dome" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#ffffff"/><stop offset=".4" stop-color="#b6f1ff"/><stop offset="1" stop-color="#3aa6d6"/></radialGradient>` +
    `<linearGradient id="enc-sbeam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9ff0ff" stop-opacity=".7"/><stop offset="1" stop-color="#5fd8ff" stop-opacity="0"/></linearGradient>` +
    // 3 tic-tac
    `<linearGradient id="enc-tic" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset=".55" stop-color="#eaf2ff"/><stop offset="1" stop-color="#a3b6dc"/></linearGradient>` +
    `<linearGradient id="enc-trail" gradientUnits="userSpaceOnUse" x1="4" y1="0" x2="24" y2="0"><stop offset="0" stop-color="#cfe0ff" stop-opacity="0"/><stop offset="1" stop-color="#eaf2ff"/></linearGradient>` +
    // 4 black triangle
    `<radialGradient id="enc-tric" cx=".5" cy=".38" r=".6"><stop offset="0" stop-color="#3a1a72"/><stop offset="1" stop-color="#12062a"/></radialGradient>` +
    `<radialGradient id="enc-vlite"><stop offset="0" stop-color="#fff"/><stop offset=".3" stop-color="#ead8ff"/><stop offset=".6" stop-color="#b46bff" stop-opacity=".55"/><stop offset="1" stop-color="#b46bff" stop-opacity="0"/></radialGradient>` +
    // 5 pyramid
    `<linearGradient id="enc-plit" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff0c0"/><stop offset=".45" stop-color="#ffc24a"/><stop offset="1" stop-color="#e08e1c"/></linearGradient>` +
    `<linearGradient id="enc-pdark" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#c47c1a"/><stop offset="1" stop-color="#7e4508"/></linearGradient>` +
    `<linearGradient id="enc-pbeam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff6c8" stop-opacity="0"/><stop offset="1" stop-color="#fff6c8"/></linearGradient>` +
    `<radialGradient id="enc-gold"><stop offset="0" stop-color="#fff"/><stop offset=".35" stop-color="#fff3b0"/><stop offset="1" stop-color="#ffc24a" stop-opacity="0"/></radialGradient>` +
    // 6 crop circle
    `<linearGradient id="enc-field" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6ffb0"/><stop offset=".45" stop-color="#d7f25a"/><stop offset="1" stop-color="#83a018"/></linearGradient>` +
    `<clipPath id="enc-fclip"><rect x="6" y="6" width="52" height="52" rx="10"/></clipPath>` +
    // 7 ray gun
    `<radialGradient id="enc-gun" cx=".3" cy=".25" r=".85"><stop offset="0" stop-color="#ffc4bb"/><stop offset=".4" stop-color="#ff5a5a"/><stop offset="1" stop-color="#a8142a"/></radialGradient>` +
    `<linearGradient id="enc-chrome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#d3d9e6"/><stop offset="1" stop-color="#6b7591"/></linearGradient>` +
    // 8 cow abduction
    `<linearGradient id="enc-cbeam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd2ef"/><stop offset=".5" stop-color="#ff9ad6" stop-opacity=".9"/><stop offset="1" stop-color="#ff6ec4" stop-opacity=".75"/></linearGradient>` +
    `<linearGradient id="enc-cow" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#d9d2e6"/></linearGradient>` +
    `<clipPath id="enc-cowclip"><rect x="17" y="26" width="28" height="16" rx="8"/></clipPath>` +
    // 9 radio dish
    `<linearGradient id="enc-dishin" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#f3f8ff"/><stop offset=".5" stop-color="#a9c6ff"/><stop offset="1" stop-color="#4d8dff"/></linearGradient>` +
    `<linearGradient id="enc-dishback" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7aa8ff"/><stop offset="1" stop-color="#2848a6"/></linearGradient>` +
    `<linearGradient id="enc-ped" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#dfe8ff"/><stop offset="1" stop-color="#5a74b8"/></linearGradient>`,
  symbols: [
    // 1 Alien Head
    `<path d="M32 5C46.5 5 56.5 14.5 56.5 27 56.5 39 45 51.5 36.5 57.5 33.8 59.4 30.2 59.4 27.5 57.5 19 51.5 7.5 39 7.5 27 7.5 14.5 17.5 5 32 5Z" fill="url(#enc-alien)" stroke="#11522f" stroke-width="2.4"/>` +
    `<path d="M11 25.5C11.8 15.5 19.5 8.6 30.5 8.3" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="1.6" stroke-linecap="round"/>` +
    `<ellipse cx="22" cy="15" rx="7" ry="3.4" transform="rotate(-28 22 15)" fill="#fff" opacity=".6"/>` +
    `<path d="M12.5 27.5C18 25 27.5 28.5 29.8 37 30.6 40.3 28 42.3 24.5 41 18 38.5 12.5 33 12.5 27.5Z" fill="url(#enc-eye)" stroke="#0a3d22" stroke-width="1.5"/>` +
    `<path d="M51.5 27.5C46 25 36.5 28.5 34.2 37 33.4 40.3 36 42.3 39.5 41 46 38.5 51.5 33 51.5 27.5Z" fill="url(#enc-eye)" stroke="#0a3d22" stroke-width="1.5"/>` +
    `<ellipse cx="18.5" cy="30" rx="3.3" ry="1.9" transform="rotate(22 18.5 30)" fill="#fff" opacity=".92"/><circle cx="26.3" cy="38" r="1.2" fill="#fff" opacity=".6"/>` +
    `<ellipse cx="40.5" cy="30.5" rx="3.3" ry="1.9" transform="rotate(-22 40.5 30.5)" fill="#fff" opacity=".92"/><circle cx="46" cy="35" r="1.2" fill="#fff" opacity=".6"/>` +
    `<path d="M21 38.6Q25 40.8 28.4 39.4M35.6 39.4Q39 40.8 43 38.6" fill="none" stroke="#5fd8ff" stroke-width="1.2" stroke-linecap="round" opacity=".75"/>` +
    `<circle cx="29.8" cy="47" r="1.1" fill="#11522f"/><circle cx="34.2" cy="47" r="1.1" fill="#11522f"/>` +
    `<path d="M28 51.4Q32 53.2 36 51.4" fill="none" stroke="#11522f" stroke-width="1.5" stroke-linecap="round"/>`,

    // 2 Flying Saucer
    `<path d="M26 42L38 42 47 59 17 59Z" fill="url(#enc-sbeam)"/>` +
    `<g transform="rotate(-10 32 34)">` +
    `<path d="M32 13V7.5" stroke="#0d4a6e" stroke-width="3.4" stroke-linecap="round"/><path d="M32 13V7.5" stroke="#bdefff" stroke-width="1.4" stroke-linecap="round"/><circle cx="32" cy="6.3" r="2.4" fill="#ff8fd1" stroke="#5a1a48" stroke-width="1.2"/>` +
    `<ellipse cx="32" cy="40" rx="13" ry="5.5" fill="#1a6f9b" stroke="#0a3a58" stroke-width="2"/>` +
    `<ellipse cx="32" cy="34.5" rx="26.5" ry="8.5" fill="url(#enc-disc)" stroke="#0a3a58" stroke-width="2.3"/>` +
    `<path d="M7 36.2Q32 47 57 36.2" fill="none" stroke="#0e5a85" stroke-width="1.5"/>` +
    `<path d="M17 33C17 19 24.5 13 32 13 39.5 13 47 19 47 33 42 35.6 22 35.6 17 33Z" fill="url(#enc-dome)" stroke="#0a3a58" stroke-width="2.2"/>` +
    `<path d="M21.6 27.5C22 21.5 25.5 17.6 29.6 16.6" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/>` +
    `<ellipse cx="17" cy="31.5" rx="6" ry="1.5" fill="#fff" opacity=".8"/>` +
    `<g stroke="#0a3a58" stroke-width="1.2"><circle cx="12" cy="38.4" r="2.3" fill="#ffe45c"/><circle cx="22" cy="40.6" r="2.3" fill="#ff8fd1"/><circle cx="32" cy="41.2" r="2.3" fill="#7cff9b"/><circle cx="42" cy="40.6" r="2.3" fill="#ff8fd1"/><circle cx="52" cy="38.4" r="2.3" fill="#ffe45c"/></g>` +
    `<g fill="#fff"><circle cx="11.4" cy="37.8" r=".8"/><circle cx="21.4" cy="40" r=".8"/><circle cx="31.4" cy="40.6" r=".8"/><circle cx="41.4" cy="40" r=".8"/><circle cx="51.4" cy="37.8" r=".8"/></g>` +
    `</g>`,

    // 3 Tic-Tac UAP
    `<g transform="rotate(-20 32 32)">` +
    `<rect x="15" y="17.5" width="46" height="29" rx="14.5" fill="#bcd2ff" opacity=".16"/>` +
    `<rect x="17.5" y="20" width="41" height="24" rx="12" fill="#dfe9ff" opacity=".3"/>` +
    `<path d="M5 32H18M8.5 25H18M8.5 39H18" stroke="url(#enc-trail)" stroke-width="2.6" stroke-linecap="round"/>` +
    `<path d="M3 32H18" stroke="url(#enc-trail)" stroke-width="4.6" stroke-linecap="round" opacity=".55"/>` +
    `<rect x="20" y="22" width="37" height="20" rx="10" fill="url(#enc-tic)" stroke="#6f86b8" stroke-width="2.2"/>` +
    `<path d="M25.5 37.3H51.5" stroke="#b9c9e8" stroke-width="1.4" stroke-linecap="round"/>` +
    `<rect x="25" y="25" width="21" height="3.4" rx="1.7" fill="#fff"/><circle cx="49.5" cy="26.7" r="1.5" fill="#fff"/>` +
    `</g>`,

    // 4 Black Triangle
    `<path d="M6 13H58L32 57Z" fill="none" stroke="#b46bff" stroke-width="9" stroke-linejoin="round" opacity=".18"/>` +
    `<path d="M6 13H58L32 57Z" fill="#2a1258" stroke="#b46bff" stroke-width="5" stroke-linejoin="round" opacity=".45"/>` +
    `<path d="M6 13H58L49 18H15Z" fill="#6c42bd"/><path d="M6 13L15 18 32 47V57Z" fill="#41237e"/><path d="M58 13L32 57V47L49 18Z" fill="#1d0b3d"/>` +
    `<path d="M15 18H49L32 47Z" fill="url(#enc-tric)"/>` +
    `<path d="M15 18H49L32 47Z" fill="none" stroke="#9a6ae8" stroke-width="1.3" stroke-linejoin="round"/>` +
    `<path d="M6 13H58L32 57Z" fill="none" stroke="#dcbcff" stroke-width="2.2" stroke-linejoin="round"/>` +
    `<path d="M14 15.4H30" stroke="#fff" stroke-width="1.4" stroke-linecap="round" opacity=".7"/>` +
    `<circle cx="32" cy="28" r="9" fill="url(#enc-vlite)" opacity=".85"/><circle cx="32" cy="28" r="2.6" fill="#ffe2f6"/>` +
    `<circle cx="11" cy="15.6" r="6.5" fill="url(#enc-vlite)"/><circle cx="53" cy="15.6" r="6.5" fill="url(#enc-vlite)"/><circle cx="32" cy="51" r="6.5" fill="url(#enc-vlite)"/>` +
    `<circle cx="11" cy="15.6" r="2.4" fill="#fff"/><circle cx="53" cy="15.6" r="2.4" fill="#fff"/><circle cx="32" cy="51" r="2.4" fill="#fff"/>`,

    // 5 Pyramid
    `<path d="M29.4 3.5H34.6L33.6 16H30.4Z" fill="url(#enc-pbeam)"/>` +
    `<path d="M32 15L40 56H4Z" fill="url(#enc-plit)"/><path d="M32 15L60 56H40Z" fill="url(#enc-pdark)"/>` +
    `<g stroke-width="1.3" fill="none" stroke-linecap="round"><path d="M26.5 23H33.6M21.1 31H35.1M15.6 39H36.7M10.2 47H38.2M28 31V23.6M24 39V31M31 39V31M19 47V39M27 47V39M34 47V39M15 55V47M23 55V47M31 55V47" stroke="#b5701a" opacity=".85"/>` +
    `<path d="M33.6 23H37.5M35.1 31H42.9M36.7 39H48.4M38.2 47H53.9M40 31V23.5M44 39V31M42 47V39M49 47V39M46 55.5V47M55 55.5V48" stroke="#5c3204" opacity=".7"/></g>` +
    `<path d="M32 15L40 56" stroke="#7a4408" stroke-width="1.4"/>` +
    `<path d="M32 15L60 56H4Z" fill="none" stroke="#6a3a06" stroke-width="2.3" stroke-linejoin="round"/>` +
    `<path d="M28.6 21.8L11.5 47.5" stroke="#fff" stroke-width="1.7" stroke-linecap="round" opacity=".5"/>` +
    `<circle cx="32" cy="17.5" r="8" fill="url(#enc-gold)"/><path d="M32 13.6L36 20.4H28Z" fill="#fff8d8" stroke="#c98a1a" stroke-width="1.2" stroke-linejoin="round"/>`,

    // 6 Crop Circle
    `<g transform="matrix(.94 0 0 .94 1.92 1.92)"><rect x="6" y="6" width="52" height="52" rx="10" fill="url(#enc-field)"/>` +
    `<g clip-path="url(#enc-fclip)" stroke="#9cb82a" stroke-width="1.3" opacity=".9"><path d="M0 12L64 2M0 18L64 8M0 24L64 14M0 30L64 20M0 36L64 26M0 42L64 32M0 48L64 38M0 54L64 44M0 60L64 50M0 66L64 56M0 72L64 62"/></g>` +
    `<circle cx="32" cy="32" r="17" fill="none" stroke="#6f8a14" stroke-width="5.6"/><circle cx="32" cy="32" r="17" fill="none" stroke="#fbffd8" stroke-width="3.2"/>` +
    `<circle cx="32" cy="32" r="9" fill="#fbffd8" stroke="#6f8a14" stroke-width="1.4"/><circle cx="32" cy="32" r="3.4" fill="#c5e046" stroke="#6f8a14" stroke-width="1.2"/>` +
    `<g fill="#fbffd8" stroke="#6f8a14" stroke-width="1.4"><circle cx="32" cy="15" r="4.6"/><circle cx="46.7" cy="40.5" r="4.6"/><circle cx="17.3" cy="40.5" r="4.6"/></g>` +
    `<rect x="6" y="6" width="52" height="52" rx="10" fill="none" stroke="#4d6409" stroke-width="2.3"/>` +
    `<path d="M9.4 24C9.4 14.5 14 9.4 23.5 9.4" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" opacity=".75"/></g>`,

    // 7 Ray Gun
    `<g transform="translate(0 -3) rotate(-16 32 32)">` +
    `<path d="M14 21L19.2 11.4C19.8 10.4 21 10.4 21.6 11.4L26.5 20.6Z" fill="#c8202f" stroke="#4a0610" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M15 37H25L22.3 53.5C21.9 56 20 57.4 17.5 57.4H14C11.5 57.4 10.2 55.6 10.7 53.2Z" fill="#b81a2a" stroke="#4a0610" stroke-width="2.2" stroke-linejoin="round"/>` +
    `<path d="M14 45.5H22.5M13.2 50.5H21.6" stroke="#6e0a16" stroke-width="1.4" stroke-linecap="round"/>` +
    `<rect x="38" y="26.5" width="15" height="7" fill="url(#enc-chrome)" stroke="#3a0a14" stroke-width="1.6"/>` +
    `<path d="M7 30C7 22.5 13 19 21 19.5L37 22C39.5 22.4 40.5 24 40.5 26V34C40.5 36 39.5 37.6 37 38L21 40.5C13 41 7 37.5 7 30Z" fill="url(#enc-gun)" stroke="#4a0610" stroke-width="2.3"/>` +
    `<path d="M28 21.4V39.2" stroke="#8a0e1e" stroke-width="1.4"/>` +
    `<circle cx="17" cy="30" r="4.6" fill="#ffe45c" stroke="#4a0610" stroke-width="1.6"/><circle cx="15.8" cy="28.8" r="1.4" fill="#fff"/>` +
    `<ellipse cx="22" cy="23.6" rx="5.5" ry="1.7" transform="rotate(5 22 23.6)" fill="#fff" opacity=".7"/>` +
    `<g fill="url(#enc-chrome)" stroke="#3a0a14" stroke-width="1.5"><ellipse cx="43" cy="30" rx="2.4" ry="7.4"/><ellipse cx="47.5" cy="30" rx="2.4" ry="6.6"/><ellipse cx="52" cy="30" rx="2.4" ry="5.8"/></g>` +
    `<path d="M53.5 27.5L57 25.5V34.5L53.5 32.5Z" fill="#ff5a5a" stroke="#3a0a14" stroke-width="1.4" stroke-linejoin="round"/>` +
    `<circle cx="58.2" cy="30" r="5" fill="url(#enc-gold)"/><circle cx="58" cy="30" r="1.8" fill="#fff"/>` +
    `</g>`,

    // 8 Cow Abduction
    `<path d="M23 7H41L58 60H6Z" fill="url(#enc-cbeam)"/>` +
    `<path d="M23 7L6 60M41 7L58 60" stroke="#ff4fb8" stroke-width="1.8"/>` +
    `<path d="M17.5 17Q32 21 46.5 17M10.5 52Q32 58 53.5 52" fill="none" stroke="#fff" stroke-width="1.4" opacity=".65"/>` +
    `<ellipse cx="32" cy="6.8" rx="15" ry="3.6" fill="#3a1650" stroke="#ff8fd1" stroke-width="1.4"/><g fill="#fff"><circle cx="24" cy="7.4" r="1.1"/><circle cx="32" cy="8" r="1.1"/><circle cx="40" cy="7.4" r="1.1"/></g>` +
    `<g transform="rotate(-12 32 34)">` +
    `<path d="M17.5 30C14 30.5 12.5 33 12.8 36.5" fill="none" stroke="#2a1030" stroke-width="1.6" stroke-linecap="round"/><circle cx="12.8" cy="37.6" r="1.9" fill="#2a1030"/>` +
    `<g fill="#fff" stroke="#2a1030" stroke-width="1.8"><rect x="19.5" y="38" width="4.2" height="11" rx="1.6"/><rect x="25.5" y="38" width="4.2" height="11" rx="1.6"/><rect x="33" y="38" width="4.2" height="11" rx="1.6"/><rect x="39" y="38" width="4.2" height="11" rx="1.6"/></g>` +
    `<g fill="#2a1030"><rect x="19.5" y="46" width="4.2" height="3" rx="1"/><rect x="25.5" y="46" width="4.2" height="3" rx="1"/><rect x="33" y="46" width="4.2" height="3" rx="1"/><rect x="39" y="46" width="4.2" height="3" rx="1"/></g>` +
    `<ellipse cx="33" cy="42" rx="3.6" ry="2.4" fill="#ffb3df" stroke="#2a1030" stroke-width="1.3"/>` +
    `<rect x="17" y="26" width="28" height="16" rx="8" fill="url(#enc-cow)"/>` +
    `<g clip-path="url(#enc-cowclip)" fill="#1e1028"><path d="M20 25C25 25 28 28 27 31.5 26 35 21 36 18 34.5 15 33 15 25 20 25Z"/><path d="M34 34.5C38 33 43 35 42.5 39 42 43 36 43.5 33.5 41.5 31.5 39.5 31.5 35.5 34 34.5Z"/><path d="M36 25C38.5 25 40 27 39 28.6 38 30.2 35 30 34.5 28.4 34 26.6 34.5 25 36 25Z"/></g>` +
    `<rect x="17" y="26" width="28" height="16" rx="8" fill="none" stroke="#2a1030" stroke-width="2"/>` +
    `<path d="M21.5 28.6H30" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".9"/>` +
    `<path d="M44 22.5L42 19.6M50.5 22.5L52.5 19.6" stroke="#f3e2b8" stroke-width="2" stroke-linecap="round"/>` +
    `<ellipse cx="41.5" cy="25.4" rx="3" ry="1.7" fill="#2a1030"/><ellipse cx="53" cy="25.4" rx="3" ry="1.7" fill="#2a1030"/>` +
    `<path d="M47.3 22C51.5 22 52.6 25.5 52.4 29.5L52 33H42.6L42.2 29.5C42 25.5 43.1 22 47.3 22Z" fill="url(#enc-cow)" stroke="#2a1030" stroke-width="1.8"/>` +
    `<path d="M44.5 23.2C46.5 22.6 48 23.4 48 25.2 48 27 45.5 27.6 43.6 26.8Z" fill="#1e1028"/>` +
    `<ellipse cx="47.3" cy="33" rx="5.6" ry="3.6" fill="#ffa6d6" stroke="#2a1030" stroke-width="1.6"/><circle cx="45.4" cy="33.2" r=".9" fill="#2a1030"/><circle cx="49.2" cy="33.2" r=".9" fill="#2a1030"/>` +
    `<circle cx="45" cy="27.8" r="1.2" fill="#2a1030"/><circle cx="49.8" cy="27.8" r="1.2" fill="#2a1030"/>` +
    `</g>`,

    // 9 Radio Dish
    `<ellipse cx="25" cy="57" rx="14" ry="2.8" fill="#1d3478" stroke="#0e1c46" stroke-width="1.4"/>` +
    `<path d="M17.5 57L21.5 41H28.5L32.5 57Z" fill="url(#enc-ped)" stroke="#0e1c46" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M21 51H29" stroke="#3d5aa0" stroke-width="1.3"/>` +
    `<circle cx="25" cy="41.5" r="3.6" fill="#b8ccff" stroke="#0e1c46" stroke-width="1.6"/>` +
    `<g transform="translate(25 36.5) rotate(40) scale(1.1)">` +
    `<path d="M-20 0A20 13 0 0 0 20 0Z" fill="url(#enc-dishback)" stroke="#0e1c46" stroke-width="2.3" stroke-linejoin="round"/>` +
    `<ellipse rx="20" ry="6" fill="url(#enc-dishin)" stroke="#0e1c46" stroke-width="2.1"/>` +
    `<ellipse rx="12.5" ry="3.7" fill="none" stroke="#5f8fe8" stroke-width="1.3"/><ellipse rx="5.5" ry="1.7" fill="none" stroke="#5f8fe8" stroke-width="1.3"/>` +
    `<path d="M-13 2.6L0-15 13 2.6" fill="none" stroke="#0e1c46" stroke-width="1.6" stroke-linejoin="round"/>` +
    `<ellipse cx="-10" cy="-1.6" rx="5" ry="1.4" fill="#fff" opacity=".8"/>` +
    `<circle cy="-15" r="2.8" fill="#eaf2ff" stroke="#0e1c46" stroke-width="1.4"/>` +
    `</g>` +
    `<g fill="none" stroke-linecap="round"><path d="M36.1 17.4A6.5 6.5 0 0 1 41.9 22.3M36.4 11.9A12 12 0 0 1 47.2 21.0M36.8 6.4A17.5 17.5 0 0 1 52.6 19.6" stroke="#0e1c46" stroke-width="4.8"/><path d="M36.1 17.4A6.5 6.5 0 0 1 41.9 22.3" stroke="#d6e6ff" stroke-width="2.6"/><path d="M36.4 11.9A12 12 0 0 1 47.2 21.0" stroke="#8fb6ff" stroke-width="2.6"/><path d="M36.8 6.4A17.5 17.5 0 0 1 52.6 19.6" stroke="#4d8dff" stroke-width="2.6"/></g>`,
  ],
};
