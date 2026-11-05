/* Space Fleet lineup: nine spacecraft as clean technical illustrations, hand-drawn SVG.
   Light comes from the top-left; every id is prefixed "flt-". */
export default {
  key: 'fleet',
  names: ['Rocket', 'Space Shuttle', 'Satellite', 'Astronaut', 'Lunar Lander', 'Space Station', 'Mars Rover', 'Space Telescope', 'Return Capsule'],
  colors: ['#FF4D5E', '#EEF3FA', '#3D7BFF', '#FF9A3D', '#FFD54A', '#37D6C2', '#C9673C', '#8E7CFF', '#5BE37A'],
  defs: `<linearGradient id="flt-white" x1="0" y1="0" x2="1" y2=".25"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".5" stop-color="#E4EBF5"/><stop offset="1" stop-color="#93A5C4"/></linearGradient>`
    + `<linearGradient id="flt-steel" x1="0" y1="0" x2="1" y2=".25"><stop offset="0" stop-color="#F2F5FA"/><stop offset=".5" stop-color="#B9C4D6"/><stop offset="1" stop-color="#6A7894"/></linearGradient>`
    + `<linearGradient id="flt-dark" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#97A3B8"/><stop offset=".5" stop-color="#4C566C"/><stop offset="1" stop-color="#232A38"/></linearGradient>`
    + `<radialGradient id="flt-glass" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#DDF2FF"/><stop offset=".45" stop-color="#4FA2FF"/><stop offset="1" stop-color="#0F3478"/></radialGradient>`
    + `<linearGradient id="flt-flame" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF7C8"/><stop offset=".35" stop-color="#FFC23D"/><stop offset=".75" stop-color="#FF6A2A"/><stop offset="1" stop-color="#FF3D2A" stop-opacity=".35"/></linearGradient>`
    + `<linearGradient id="flt-red" x1="0" y1="0" x2="1" y2=".2"><stop offset="0" stop-color="#FFA3AB"/><stop offset=".45" stop-color="#FF4D5E"/><stop offset="1" stop-color="#A9142A"/></linearGradient>`
    + `<linearGradient id="flt-panel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#A2CFFF"/><stop offset=".45" stop-color="#3D7BFF"/><stop offset="1" stop-color="#16389C"/></linearGradient>`
    + `<radialGradient id="flt-helmet" cx=".35" cy=".28" r=".85"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".55" stop-color="#E1E8F2"/><stop offset="1" stop-color="#8797B3"/></radialGradient>`
    + `<radialGradient id="flt-visor" cx=".32" cy=".28" r=".9"><stop offset="0" stop-color="#FFE9BC"/><stop offset=".38" stop-color="#FFA347"/><stop offset=".78" stop-color="#C4500C"/><stop offset="1" stop-color="#6A2606"/></radialGradient>`
    + `<linearGradient id="flt-gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF4B8"/><stop offset=".25" stop-color="#FFD54A"/><stop offset=".5" stop-color="#E5A326"/><stop offset=".68" stop-color="#FFE27A"/><stop offset="1" stop-color="#B87C10"/></linearGradient>`
    + `<linearGradient id="flt-teal" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C4FFF6"/><stop offset=".45" stop-color="#3ADBC6"/><stop offset="1" stop-color="#11706A"/></linearGradient>`
    + `<linearGradient id="flt-tealv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C4FFF6"/><stop offset=".45" stop-color="#3ADBC6"/><stop offset="1" stop-color="#11706A"/></linearGradient>`
    + `<linearGradient id="flt-spanel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9ED2D4"/><stop offset=".5" stop-color="#4C8E98"/><stop offset="1" stop-color="#1F4C58"/></linearGradient>`
    + `<linearGradient id="flt-rust" x1="0" y1="0" x2=".3" y2="1"><stop offset="0" stop-color="#F7AE88"/><stop offset=".5" stop-color="#CB693D"/><stop offset="1" stop-color="#7A3519"/></linearGradient>`
    + `<radialGradient id="flt-wheel" cx=".38" cy=".32" r=".75"><stop offset="0" stop-color="#9AA4B8"/><stop offset=".6" stop-color="#4C5468"/><stop offset="1" stop-color="#262B38"/></radialGradient>`
    + `<linearGradient id="flt-violet" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#D4CCFF"/><stop offset=".45" stop-color="#8E7CFF"/><stop offset="1" stop-color="#4632BE"/></linearGradient>`
    + `<radialGradient id="flt-mirror" cx=".4" cy=".35" r=".75"><stop offset="0" stop-color="#F4F0FF"/><stop offset=".35" stop-color="#B8AAFF"/><stop offset=".75" stop-color="#6A50FF"/><stop offset="1" stop-color="#2A1A7A"/></radialGradient>`
    + `<linearGradient id="flt-green" gradientUnits="userSpaceOnUse" x1="8" y1="4" x2="50" y2="28"><stop offset="0" stop-color="#CBFFD7"/><stop offset=".45" stop-color="#5BE37A"/><stop offset="1" stop-color="#1D883B"/></linearGradient>`
    + `<linearGradient id="flt-chw" gradientUnits="userSpaceOnUse" x1="8" y1="4" x2="50" y2="28"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".5" stop-color="#E2E9F3"/><stop offset="1" stop-color="#A0B0C8"/></linearGradient>`,
  symbols: [
    // 1. Rocket
    `<path d="M24.5 50.5Q25.5 55.5 32 60Q38.5 55.5 39.5 50.5Z" fill="url(#flt-flame)"/><path d="M28 50.5Q29 54.5 32 56.5Q35 54.5 36 50.5Z" fill="#FFF8D6"/>`
    + `<path d="M22 28.5C14.5 32.5 9.5 39.5 9.5 47.5V54L22 46.5ZM42 28.5C49.5 32.5 54.5 39.5 54.5 47.5V54L42 46.5Z" fill="url(#flt-red)" stroke="#5A0F1A" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M25.5 46H38.5L40.5 51H23.5Z" fill="url(#flt-dark)" stroke="#1E2433" stroke-width="2" stroke-linejoin="round"/>`
    + `<path d="M32 4C40 10 42.5 20 42.5 31V46.5H21.5V31C21.5 20 24 10 32 4Z" fill="url(#flt-white)"/>`
    + `<path d="M32 4C36.6 7.6 39.6 13 41.2 19.5H22.8C24.4 13 27.4 7.6 32 4Z" fill="url(#flt-red)"/><rect x="21.5" y="38.5" width="21" height="4" fill="url(#flt-red)"/>`
    + `<path d="M21.5 19.5H42.5M21.5 35H42.5" stroke="#7D8CA8" stroke-width="1.3"/>`
    + `<circle cx="32" cy="27.5" r="5.4" fill="url(#flt-glass)" stroke="#55627A" stroke-width="2"/><circle cx="30.2" cy="25.7" r="1.6" fill="#fff"/>`
    + `<path d="M26 21.5Q25.2 29 25.5 37" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity=".9"/><path d="M28.5 8.5Q26 11.5 25 15.5" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".6"/>`
    + `<path d="M32 4C40 10 42.5 20 42.5 31V46.5H21.5V31C21.5 20 24 10 32 4Z" fill="none" stroke="#2A2F45" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M30.3 38H33.7L34.6 53.5Q32 55.3 29.4 53.5Z" fill="url(#flt-red)" stroke="#5A0F1A" stroke-width="1.8" stroke-linejoin="round"/>`,

    // 2. Space Shuttle
    `<g transform="translate(36.4 30.1) scale(1.1) translate(-32 -32) rotate(38 32 32)"><path d="M27 56.5Q32 66 37 56.5Z" fill="url(#flt-flame)"/>`
    + `<path d="M27.4 55L26.8 58.2H31L30.6 55ZM33.4 55L33 58.2H37.2L36.6 55Z" fill="#4C566C" stroke="#1E2433" stroke-width="1.2"/>`
    + `<path d="M32 4C35.4 6 37 11 37 19L38.5 29.5L51 45.5Q53.2 49.5 49 50.2L38 51.2L37.5 55H26.5L26 51.2L15 50.2Q10.8 49.5 13 45.5L25.5 29.5L27 19C27 11 28.6 6 32 4Z" fill="url(#flt-white)"/>`
    + `<path d="M27 19L25.5 29.5L13 45.5L15.8 46.6L27.4 32L29 20ZM37 19L38.5 29.5L51 45.5L48.2 46.6L36.6 32L35 20Z" fill="#1D2433"/>`
    + `<path d="M32 4C34.2 5.3 35.4 7.3 36 9.6H28C28.6 7.3 29.8 5.3 32 4Z" fill="#1D2433"/><path d="M28.8 12.3H35.2L34.4 14.8H29.6Z" fill="#1D2433"/>`
    + `<path d="M29.3 19V45M34.7 19V45M15.5 48.2H26M38 48.2H48.5" stroke="#8597B8" stroke-width="1.3" fill="none"/><path d="M29.3 19H34.7M29.3 32H34.7M29.3 45H34.7" stroke="#8597B8" stroke-width="1.2"/>`
    + `<path d="M28.6 17V40" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/>`
    + `<path d="M32 4C35.4 6 37 11 37 19L38.5 29.5L51 45.5Q53.2 49.5 49 50.2L38 51.2L37.5 55H26.5L26 51.2L15 50.2Q10.8 49.5 13 45.5L25.5 29.5L27 19C27 11 28.6 6 32 4Z" fill="none" stroke="#3A4E74" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<rect x="30.9" y="40" width="2.2" height="16.5" rx="1" fill="#C9D3E3" stroke="#3A4E74" stroke-width="1.2"/></g>`,

    // 3. Satellite
    `<path d="M32 45V54" stroke="#2A3550" stroke-width="3.6" stroke-linecap="round"/><path d="M32 45V54" stroke="#C8D0DE" stroke-width="1.6" stroke-linecap="round"/><circle cx="32" cy="55.5" r="2.2" fill="#FF8A3D" stroke="#5A2A10" stroke-width="1.2"/>`
    + `<rect x="19" y="30.5" width="26" height="3" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.4"/>`
    + `<rect x="5" y="21" width="16" height="22" rx="1.5" fill="url(#flt-panel)" stroke="#0E1F5A" stroke-width="2.2"/><rect x="43" y="21" width="16" height="22" rx="1.5" fill="url(#flt-panel)" stroke="#0E1F5A" stroke-width="2.2"/>`
    + `<path d="M13 21V43M5 26.5H21M5 32H21M5 37.5H21M51 21V43M43 26.5H59M43 32H59M43 37.5H59" stroke="#0E2A78" stroke-width="1.3"/>`
    + `<path d="M6.5 22.5H12.5L6.5 31ZM44.5 22.5H50.5L44.5 31Z" fill="#fff" opacity=".35"/>`
    + `<path d="M32 18V13.5" stroke="#2A3550" stroke-width="3.4"/><path d="M32 18V13.5" stroke="#C8D0DE" stroke-width="1.6"/>`
    + `<rect x="24" y="17" width="16" height="28" rx="2" fill="url(#flt-steel)"/><rect x="24" y="36.5" width="16" height="3.5" fill="#FF8A3D"/>`
    + `<path d="M24 23H40" stroke="#7D8AA3" stroke-width="1.3"/><circle cx="32" cy="29.5" r="3.2" fill="url(#flt-glass)" stroke="#2A3550" stroke-width="1.4"/>`
    + `<path d="M26.5 19.5V34" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".85"/>`
    + `<rect x="24" y="17" width="16" height="28" rx="2" fill="none" stroke="#2A3550" stroke-width="2.2"/>`
    + `<path d="M32 13V6.5" stroke="#2A3550" stroke-width="1.6"/><circle cx="32" cy="6" r="1.8" fill="#FF8A3D" stroke="#5A2A10" stroke-width="1.2"/>`
    + `<path d="M21 11Q32 20.5 43 11Q32 15 21 11Z" fill="url(#flt-white)" stroke="#2A3550" stroke-width="1.8" stroke-linejoin="round"/>`,

    // 4. Astronaut
    `<path d="M7 59V55C7 47.5 13 43 21 42H43C51 43 57 47.5 57 55V59Z" fill="url(#flt-white)" stroke="#2A3550" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M11 51.5L17.5 47.5M53 51.5L46.5 47.5" stroke="#FF8A3D" stroke-width="2.6" stroke-linecap="round"/>`
    + `<rect x="25" y="50" width="14" height="8" rx="1.8" fill="#DCE3ED" stroke="#2A3550" stroke-width="1.6"/><circle cx="29" cy="54" r="1.5" fill="#FF8A3D"/><circle cx="35" cy="54" r="1.5" fill="#3D7BFF"/>`
    + `<rect x="19" y="41" width="26" height="6" rx="3" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="2"/>`
    + `<circle cx="32" cy="26" r="21" fill="url(#flt-helmet)" stroke="#2A3550" stroke-width="2.4"/>`
    + `<rect x="8.5" y="21" width="5" height="11" rx="2" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.6"/><rect x="50.5" y="21" width="5" height="11" rx="2" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.6"/>`
    + `<path d="M15.5 15Q19.5 8.5 27 6.8" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity=".95"/>`
    + `<path d="M14.5 26C14.5 16.5 22 11 32 11C42 11 49.5 16.5 49.5 26C49.5 35.5 42 40.5 32 40.5C22 40.5 14.5 35.5 14.5 26Z" fill="url(#flt-visor)" stroke="#5A2508" stroke-width="2"/>`
    + `<path d="M17.5 32Q32 26.5 46.5 32" fill="none" stroke="#FFE3B0" stroke-width="1.4" opacity=".55"/>`
    + `<path d="M19.5 23Q21.5 16 29 14.2" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" opacity=".9"/><ellipse cx="42" cy="34" rx="3" ry="1.5" transform="rotate(-30 42 34)" fill="#fff" opacity=".5"/>`,

    // 5. Lunar Lander
    `<g fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M16 36L9 53M20 46L12 47.5M48 36L55 53M44 46L52 47.5" stroke="#2A2F45" stroke-width="4.4"/><path d="M16 36L9 53M20 46L12 47.5M48 36L55 53M44 46L52 47.5" stroke="#C8D0DE" stroke-width="2"/></g>`
    + `<ellipse cx="9" cy="54.5" rx="4.2" ry="1.8" fill="url(#flt-steel)" stroke="#2A2F45" stroke-width="1.4"/><ellipse cx="55" cy="54.5" rx="4.2" ry="1.8" fill="url(#flt-steel)" stroke="#2A2F45" stroke-width="1.4"/>`
    + `<path d="M41 11L45.5 6.5" stroke="#2A3550" stroke-width="1.6"/><circle cx="46" cy="6.5" r="2.2" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.2"/>`
    + `<path d="M19 25L21 15L27 9.5H37L43 14L45 25Z" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M24.5 14.5H29.5L28 19.5ZM39.5 14.5H34.5L36 19.5Z" fill="url(#flt-glass)" stroke="#1D2433" stroke-width="1.2" stroke-linejoin="round"/>`
    + `<rect x="29" y="18.5" width="6" height="6" rx="1" fill="#9AA6BC" stroke="#2A3550" stroke-width="1.3"/><path d="M17 18H22M19.5 15.5V20.5" stroke="#2A3550" stroke-width="1.6" stroke-linecap="round"/>`
    + `<path d="M23.5 11.5L22 15" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".8"/>`
    + `<path d="M26.5 47H37.5L40 52H24Z" fill="url(#flt-dark)" stroke="#1E2433" stroke-width="1.6" stroke-linejoin="round"/>`
    + `<path d="M14 30L20 25H44L50 30V42L44 47H20L14 42Z" fill="url(#flt-gold)" stroke="#6B4A08" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M20 25V47M44 25V47" stroke="#A86E10" stroke-width="1.4"/><path d="M21.5 26.5H31L25 35ZM33 39L42.5 29.5V45.5H39Z" fill="#FFF8D0" opacity=".45"/><path d="M21.5 45.5L27 38L31 45.5ZM34 26.5H42.5L37.5 33Z" fill="#8A5606" opacity=".3"/>`
    + `<path d="M16 31.5V40.5" stroke="#FFF8D0" stroke-width="1.6" stroke-linecap="round" opacity=".8"/>`
    + `<path d="M32 47V56" stroke="#2A2F45" stroke-width="4.4" stroke-linecap="round"/><path d="M32 47V56" stroke="#C8D0DE" stroke-width="2" stroke-linecap="round"/><ellipse cx="32" cy="57.5" rx="5" ry="2" fill="url(#flt-steel)" stroke="#2A2F45" stroke-width="1.4"/>`,

    // 6. Space Station
    `<rect x="5" y="6" width="12" height="22" rx="1" fill="url(#flt-spanel)" stroke="#9FD8DA" stroke-width="1.6"/><rect x="5" y="36" width="12" height="22" rx="1" fill="url(#flt-spanel)" stroke="#9FD8DA" stroke-width="1.6"/>`
    + `<rect x="47" y="6" width="12" height="22" rx="1" fill="url(#flt-spanel)" stroke="#9FD8DA" stroke-width="1.6"/><rect x="47" y="36" width="12" height="22" rx="1" fill="url(#flt-spanel)" stroke="#9FD8DA" stroke-width="1.6"/>`
    + `<path d="M11 6V28M5 11.5H17M5 17H17M5 22.5H17M11 36V58M5 41.5H17M5 47H17M5 52.5H17M53 6V28M47 11.5H59M47 17H59M47 22.5H59M53 36V58M47 41.5H59M47 47H59M47 52.5H59" stroke="#1B4A55" stroke-width="1.3"/>`
    + `<rect x="5" y="30" width="54" height="4" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.6"/><path d="M8 30L11 34L14 30L17 34M47 34L50 30L53 34L56 30" fill="none" stroke="#5E6C88" stroke-width="1.2"/>`
    + `<rect x="29.5" y="5.5" width="5" height="5" rx="1" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.4"/><rect x="29.5" y="53.5" width="5" height="5" rx="1" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.4"/>`
    + `<rect x="27" y="9.5" width="10" height="45" rx="4" fill="url(#flt-teal)" stroke="#0B4A43" stroke-width="2.2"/>`
    + `<rect x="18" y="27" width="28" height="10" rx="4" fill="url(#flt-tealv)" stroke="#0B4A43" stroke-width="2.2"/>`
    + `<path d="M27 18H37M27 46H37M24 27V37M40 27V37" stroke="#0B4A43" stroke-width="1.4"/>`
    + `<circle cx="32" cy="32" r="5.5" fill="url(#flt-teal)" stroke="#0B4A43" stroke-width="2"/><circle cx="32" cy="32" r="1.8" fill="#FF8A3D"/>`
    + `<path d="M29.5 12.5V24M20.5 29.5H25" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".85"/><circle cx="32" cy="50" r="1.4" fill="#E2FFFA"/><circle cx="32" cy="14" r="1.4" fill="#E2FFFA"/>`,

    // 7. Mars Rover
    `<circle cx="18" cy="47" r="6" fill="#3A4152" stroke="#151A26" stroke-width="1.8"/><circle cx="35" cy="47" r="6" fill="#3A4152" stroke="#151A26" stroke-width="1.8"/><circle cx="52" cy="47" r="6" fill="#3A4152" stroke="#151A26" stroke-width="1.8"/>`
    + `<rect x="5.5" y="22" width="8" height="9" rx="2" transform="rotate(-25 9.5 26.5)" fill="url(#flt-dark)" stroke="#1E2433" stroke-width="1.6"/>`
    + `<path d="M54.5 33L58.5 39.5L56.5 45" fill="none" stroke="#2A2F45" stroke-width="3.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M54.5 33L58.5 39.5L56.5 45" fill="none" stroke="#C8D0DE" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><circle cx="56.5" cy="46.5" r="2.3" fill="#FF8A3D" stroke="#5A2A10" stroke-width="1.2"/>`
    + `<rect x="41.5" y="10" width="3" height="15" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.4"/>`
    + `<path d="M26 22.5V18.5" stroke="#2A3550" stroke-width="1.8"/><ellipse cx="26" cy="18" rx="5" ry="2" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="1.4"/>`
    + `<path d="M8 28L12 24H51L56 28V39H8Z" fill="url(#flt-rust)" stroke="#4A1E0C" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M8 28H56M21 28V39M41 28V39" stroke="#8A3F1E" stroke-width="1.3"/><path d="M12.5 26H40" stroke="#FFD2B8" stroke-width="1.4" stroke-linecap="round" opacity=".8"/>`
    + `<g fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M14 51L21 42L32 51M21 42L44 40L50 51" stroke="#2A2F45" stroke-width="3.8"/><path d="M14 51L21 42L32 51M21 42L44 40L50 51" stroke="#C8D0DE" stroke-width="1.6"/></g>`
    + `<rect x="36" y="4.5" width="15" height="7.5" rx="2" fill="url(#flt-white)" stroke="#2A3550" stroke-width="2"/><circle cx="41.5" cy="8.2" r="2" fill="url(#flt-glass)" stroke="#2A3550" stroke-width="1.2"/><circle cx="47" cy="8.2" r="2" fill="url(#flt-glass)" stroke="#2A3550" stroke-width="1.2"/>`
    + `<g stroke="#10141E" stroke-width="2"><circle cx="14" cy="51" r="7" fill="url(#flt-wheel)"/><circle cx="32" cy="51" r="7" fill="url(#flt-wheel)"/><circle cx="50" cy="51" r="7" fill="url(#flt-wheel)"/></g>`
    + `<g fill="none" stroke="#7A8498" stroke-width="1.5" stroke-dasharray="2.2 1.8"><circle cx="14" cy="51" r="5"/><circle cx="32" cy="51" r="5"/><circle cx="50" cy="51" r="5"/></g>`
    + `<g fill="#E08A5E" stroke="#4A1E0C" stroke-width="1.2"><circle cx="14" cy="51" r="2.4"/><circle cx="32" cy="51" r="2.4"/><circle cx="50" cy="51" r="2.4"/></g>`,

    // 8. Space Telescope
    `<g transform="translate(32.5 33.3) scale(.88) translate(-32 -32) rotate(40 32 32)">`
    + `<path d="M16 33H24M40 33H48" stroke="#2A3550" stroke-width="4"/><path d="M16 33H24M40 33H48" stroke="#C8D0DE" stroke-width="2"/>`
    + `<rect x="7" y="16" width="9" height="34" rx="1" fill="url(#flt-violet)" stroke="#241A6A" stroke-width="2.2"/><rect x="48" y="16" width="9" height="34" rx="1" fill="url(#flt-violet)" stroke="#241A6A" stroke-width="2.2"/>`
    + `<path d="M11.5 16V50M7 24.5H16M7 33H16M7 41.5H16M52.5 16V50M48 24.5H57M48 33H57M48 41.5H57" stroke="#2E2280" stroke-width="1.4"/>`
    + `<rect x="22" y="34" width="20" height="18" rx="3" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="2.4"/><path d="M22 43H42" stroke="#7D8AA3" stroke-width="1.4"/>`
    + `<rect x="24" y="12" width="16" height="24" rx="1.5" fill="url(#flt-white)" stroke="#2A3550" stroke-width="2.4"/><path d="M24 20H40M24 28H40" stroke="#8794AC" stroke-width="1.4"/>`
    + `<path d="M27 14V33" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/>`
    + `<ellipse cx="32" cy="12" rx="8.2" ry="3.8" fill="#141A2E" stroke="#2A3550" stroke-width="2"/><ellipse cx="32" cy="12.5" rx="5.8" ry="2.5" fill="url(#flt-mirror)"/><circle cx="30.3" cy="11.8" r="1" fill="#fff"/>`
    + `<ellipse cx="21" cy="7.5" rx="2.4" ry="6.8" transform="rotate(-42 21 7.5)" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="2"/></g>`,

    // 9. Return Capsule
    `<path d="M6 26C6 12 17.5 4.5 32 4.5C29.7 4.5 16.4 12 16.4 26Q11.2 22.5 6 26Z" fill="url(#flt-green)"/>`
    + `<path d="M16.4 26C16.4 12 25 4.5 32 4.5C30.8 4.5 26.8 12 26.8 26Q21.6 22.5 16.4 26Z" fill="url(#flt-chw)"/>`
    + `<path d="M26.8 26C26.8 12 29.7 4.5 32 4.5C34.3 4.5 37.2 12 37.2 26Q32 22.5 26.8 26Z" fill="url(#flt-green)"/>`
    + `<path d="M37.2 26C37.2 12 33.2 4.5 32 4.5C39 4.5 47.6 12 47.6 26Q42.4 22.5 37.2 26Z" fill="url(#flt-chw)"/>`
    + `<path d="M47.6 26C47.6 12 34.3 4.5 32 4.5C46.5 4.5 58 12 58 26Q52.8 22.5 47.6 26Z" fill="url(#flt-green)"/>`
    + `<path d="M12 18Q15 10 24 7" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" opacity=".7"/>`
    + `<path d="M6 26C6 12 17.5 4.5 32 4.5C46.5 4.5 58 12 58 26Q52.8 22.5 47.6 26Q42.4 22.5 37.2 26Q32 22.5 26.8 26Q21.6 22.5 16.4 26Q11.2 22.5 6 26Z" fill="none" stroke="#12502A" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M6.5 26.5L31 41.5M16.4 26.5L31.5 41.5M26.8 26.5L32 41.5M37.2 26.5L32 41.5M47.6 26.5L32.5 41.5M57.5 26.5L33 41.5" stroke="#E6EDF7" stroke-width="1.3" opacity=".85"/>`
    + `<path d="M26.5 43H37.5L44.5 53.5Q32 57.5 19.5 53.5Z" fill="url(#flt-steel)" stroke="#2A3550" stroke-width="2.2" stroke-linejoin="round"/>`
    + `<path d="M19.5 53.5Q32 57.5 44.5 53.5L45 55.5Q32 60 19 55.5Z" fill="#5A3A28" stroke="#2A3550" stroke-width="1.6" stroke-linejoin="round"/>`
    + `<path d="M23.2 48H40.8" stroke="#7D8AA3" stroke-width="1.3"/><circle cx="28.5" cy="50.5" r="2" fill="url(#flt-glass)" stroke="#2A3550" stroke-width="1.2"/>`
    + `<rect x="28.5" y="40.5" width="7" height="3" rx="1" fill="#FF8A3D" stroke="#5A2A10" stroke-width="1.2"/>`,
  ],
};
