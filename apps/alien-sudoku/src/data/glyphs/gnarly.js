/* PLACEHOLDER: copy of Alien Creatures until the lineup's own art lands. */
/* Alien Creatures lineup: nine cartoon alien characters, hand-drawn SVG.
   Light comes from the top-left; every id is prefixed "gnr-". */
export default {
  key: 'gnarly',
  names: ['Maw Worm', 'Hundred Eyes', 'Fang Parasite', 'Hive Queen', 'Bone Reaper', 'Bile Blob', 'Tentacle Horror', 'Mandible Ravager', 'Spine Crawler'],
  colors: ['#A9C7E8', '#7CFF4F', '#FF5CA8', '#A35CFF', '#FFD23F', '#3DFFC8', '#FF8A2A', '#5AA0FF', '#FF4A4A'],
  defs: `<radialGradient id="gnr-grey" cx=".38" cy=".28" r=".8"><stop offset="0" stop-color="#F4F9FF"/><stop offset=".45" stop-color="#B6CEEA"/><stop offset="1" stop-color="#7090B8"/></radialGradient>`
    + `<radialGradient id="gnr-void" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#46557A"/><stop offset=".55" stop-color="#141C30"/><stop offset="1" stop-color="#05070D"/></radialGradient>`
    + `<radialGradient id="gnr-lime" cx=".36" cy=".3" r=".8"><stop offset="0" stop-color="#E4FFC4"/><stop offset=".45" stop-color="#86FF57"/><stop offset="1" stop-color="#36B21C"/></radialGradient>`
    + `<radialGradient id="gnr-tip" cx=".35" cy=".3" r=".75"><stop offset="0" stop-color="#FFFFE0"/><stop offset=".5" stop-color="#F2FF6A"/><stop offset="1" stop-color="#A9D61C"/></radialGradient>`
    + `<radialGradient id="gnr-pink" cx=".36" cy=".28" r=".8"><stop offset="0" stop-color="#FFD6EA"/><stop offset=".45" stop-color="#FF67B0"/><stop offset="1" stop-color="#C21F74"/></radialGradient>`
    + `<radialGradient id="gnr-sclera" cx=".38" cy=".32" r=".75"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".7" stop-color="#F6EDF7"/><stop offset="1" stop-color="#D9C4E0"/></radialGradient>`
    + `<radialGradient id="gnr-iris" cx=".4" cy=".35" r=".7"><stop offset="0" stop-color="#C98BFF"/><stop offset=".6" stop-color="#7A2BC8"/><stop offset="1" stop-color="#3C0F6E"/></radialGradient>`
    + `<radialGradient id="gnr-purple" cx=".36" cy=".28" r=".8"><stop offset="0" stop-color="#EBDCFF"/><stop offset=".45" stop-color="#AE6EFF"/><stop offset="1" stop-color="#6224C2"/></radialGradient>`
    + `<linearGradient id="gnr-gold" x1="0" y1="0" x2=".45" y2="1"><stop offset="0" stop-color="#FFF4B0"/><stop offset=".4" stop-color="#FFD640"/><stop offset="1" stop-color="#D39612"/></linearGradient>`
    + `<linearGradient id="gnr-screen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2C3A4C"/><stop offset="1" stop-color="#0C131C"/></linearGradient>`
    + `<radialGradient id="gnr-goo" cx=".38" cy=".38" r=".8"><stop offset="0" stop-color="#E2FFF8"/><stop offset=".45" stop-color="#4FFFD0"/><stop offset="1" stop-color="#0E9E7E"/></radialGradient>`
    + `<radialGradient id="gnr-orange" cx=".38" cy=".28" r=".8"><stop offset="0" stop-color="#FFE3BE"/><stop offset=".45" stop-color="#FF9535"/><stop offset="1" stop-color="#C24C08"/></radialGradient>`
    + `<radialGradient id="gnr-bug" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".55" stop-color="#FFF0D6"/><stop offset="1" stop-color="#EDB57E"/></radialGradient>`
    + `<linearGradient id="gnr-cryst" x1="0" y1="0" x2=".6" y2="1"><stop offset="0" stop-color="#C2E0FF"/><stop offset=".5" stop-color="#6AAAFF"/><stop offset="1" stop-color="#3876E0"/></linearGradient>`
    + `<radialGradient id="gnr-red" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="#FFC9BE"/><stop offset=".45" stop-color="#FF5450"/><stop offset="1" stop-color="#B51A26"/></radialGradient>`,
  symbols: [
    // 1. Grey Visitor
    `<path d="M32 4C46.5 4 56.5 13.5 56.5 26.5C56.5 37 50 45 43.5 51.5C39.5 55.5 36 59 32 59C28 59 24.5 55.5 20.5 51.5C14 45 7.5 37 7.5 26.5C7.5 13.5 17.5 4 32 4Z" fill="url(#gnr-grey)" stroke="#3E5677" stroke-width="2.4" stroke-linejoin="round"/>`
    + `<ellipse cx="21" cy="12.5" rx="8" ry="3.8" transform="rotate(-28 21 12.5)" fill="#fff" opacity=".6"/>`
    + `<path d="M11.5 27C16 22.5 26 25 29.5 33C31 38.5 26.5 42 21 38.5C15.5 35 11 32 11.5 27Z" fill="url(#gnr-void)" stroke="#26344F" stroke-width="1.8" stroke-linejoin="round"/>`
    + `<path d="M52.5 27C48 22.5 38 25 34.5 33C33 38.5 37.5 42 43 38.5C48.5 35 53 32 52.5 27Z" fill="url(#gnr-void)" stroke="#26344F" stroke-width="1.8" stroke-linejoin="round"/>`
    + `<circle cx="17.5" cy="28.5" r="2.6" fill="#fff"/><circle cx="23" cy="33.5" r="1.3" fill="#fff" opacity=".8"/><circle cx="42.5" cy="30.5" r="2.6" fill="#fff"/><circle cx="47" cy="34" r="1.3" fill="#fff" opacity=".8"/>`
    + `<path d="M30 45.5v1.2M34 45.5v1.2" stroke="#4E6789" stroke-width="1.5" stroke-linecap="round"/>`
    + `<path d="M27.5 50.5Q32 53 36.5 50.5" fill="none" stroke="#3E5677" stroke-width="1.7" stroke-linecap="round"/>`,

    // 2. Antenna Buddy
    `<path d="M25 21Q22 13 15.5 10M39 21Q42 13 48.5 10" fill="none" stroke="#1E6E12" stroke-width="4.6" stroke-linecap="round"/>`
    + `<path d="M25 21Q22 13 15.5 10M39 21Q42 13 48.5 10" fill="none" stroke="#8BF25E" stroke-width="2.2" stroke-linecap="round"/>`
    + `<circle cx="13.5" cy="9" r="5" fill="url(#gnr-tip)" stroke="#1E6E12" stroke-width="2"/><circle cx="50.5" cy="9" r="5" fill="url(#gnr-tip)" stroke="#1E6E12" stroke-width="2"/>`
    + `<circle cx="12" cy="7.5" r="1.5" fill="#fff"/><circle cx="49" cy="7.5" r="1.5" fill="#fff"/>`
    + `<ellipse cx="22.5" cy="55.5" rx="6" ry="3.6" fill="#4FD02E" stroke="#1E6E12" stroke-width="2"/><ellipse cx="41.5" cy="55.5" rx="6" ry="3.6" fill="#4FD02E" stroke="#1E6E12" stroke-width="2"/>`
    + `<ellipse cx="32" cy="37" rx="22" ry="20" fill="url(#gnr-lime)" stroke="#1E6E12" stroke-width="2.4"/>`
    + `<ellipse cx="21" cy="23" rx="7" ry="3.4" transform="rotate(-25 21 23)" fill="#fff" opacity=".55"/>`
    + `<ellipse cx="24.5" cy="34" rx="6" ry="7" fill="#fff" stroke="#1E6E12" stroke-width="1.7"/><ellipse cx="39.5" cy="34" rx="6" ry="7" fill="#fff" stroke="#1E6E12" stroke-width="1.7"/>`
    + `<circle cx="25.8" cy="35.5" r="3.7" fill="#10240A"/><circle cx="40.8" cy="35.5" r="3.7" fill="#10240A"/>`
    + `<circle cx="24.5" cy="34" r="1.5" fill="#fff"/><circle cx="39.5" cy="34" r="1.5" fill="#fff"/>`
    + `<ellipse cx="15.5" cy="43" rx="3.4" ry="2.1" fill="#FF7FB0" opacity=".6"/><ellipse cx="48.5" cy="43" rx="3.4" ry="2.1" fill="#FF7FB0" opacity=".6"/>`
    + `<path d="M21.5 44Q32 47 42.5 44Q41 53 32 53Q23 53 21.5 44Z" fill="#14380C" stroke="#1E6E12" stroke-width="1.6" stroke-linejoin="round"/>`
    + `<ellipse cx="32" cy="50" rx="4.5" ry="2" fill="#FF6F9A"/>`,

    // 3. Cyclops Blob
    `<path d="M9 48C6 38 8 24 16 16C19 13 22 13 24 11C27 7 37 7 40 11C42 13 45 13 48 16C56 24 58 38 55 48C57 53 55 57 51 57C48 57 47 55.5 45 55.5C43 58 38 59 36 56.5C34 59 30 59 28 56.5C26 59 21 58 19 55.5C17 55.5 16 57 13 57C9 57 7 53 9 48Z" fill="url(#gnr-pink)" stroke="#7E1048" stroke-width="2.4" stroke-linejoin="round"/>`
    + `<ellipse cx="19" cy="21" rx="5.5" ry="3" transform="rotate(-40 19 21)" fill="#fff" opacity=".6"/>`
    + `<circle cx="14.5" cy="40" r="2.2" fill="#D5348A" opacity=".7"/><circle cx="50" cy="37" r="1.9" fill="#D5348A" opacity=".7"/><circle cx="47" cy="47" r="1.5" fill="#D5348A" opacity=".7"/>`
    + `<circle cx="32" cy="30" r="12.5" fill="url(#gnr-sclera)" stroke="#7E1048" stroke-width="2"/>`
    + `<circle cx="33.5" cy="31" r="7.5" fill="url(#gnr-iris)"/><circle cx="33.8" cy="31.3" r="3.6" fill="#16041F"/>`
    + `<circle cx="30.5" cy="28" r="2.7" fill="#fff"/><circle cx="36.8" cy="34" r="1.2" fill="#fff" opacity=".85"/>`
    + `<path d="M20.5 23.5Q32 13.5 43.5 23.5" fill="none" stroke="#7E1048" stroke-width="1.6" stroke-linecap="round"/>`
    + `<path d="M25 46Q32 51.5 39 46" fill="none" stroke="#7E1048" stroke-width="2" stroke-linecap="round"/><path d="M29.3 48L30.8 51.2L32.4 48.7Z" fill="#fff" stroke="#7E1048" stroke-width="1.2" stroke-linejoin="round"/>`,

    // 4. Tentacle Thinker
    `<g transform="translate(32 32) scale(.97) translate(-32 -32)"><g fill="none" stroke-linecap="round"><path d="M18 34C14 41 8 41 7 47.5C6 53 11 55.5 13.5 52.5M25 37C22.5 45 17 49 18.5 54.5C20 58.5 25 57 24.5 53.5M32 38C32 46 29.5 51 32 55.5C34 58.5 38 57 37.5 53.5M39 37C41.5 45 47 49 45.5 54.5C44 58.5 39 57 39.5 53.5M46 34C50 41 56 41 57 47.5C58 53 53 55.5 50.5 52.5" stroke="#3D137F" stroke-width="7.4"/>`
    + `<path d="M18 34C14 41 8 41 7 47.5C6 53 11 55.5 13.5 52.5M25 37C22.5 45 17 49 18.5 54.5C20 58.5 25 57 24.5 53.5M32 38C32 46 29.5 51 32 55.5C34 58.5 38 57 37.5 53.5M39 37C41.5 45 47 49 45.5 54.5C44 58.5 39 57 39.5 53.5M46 34C50 41 56 41 57 47.5C58 53 53 55.5 50.5 52.5" stroke="#9A52F2" stroke-width="3.8"/></g>`
    + `<circle cx="9.5" cy="47" r="1.1" fill="#E3CCFF"/><circle cx="54.5" cy="47" r="1.1" fill="#E3CCFF"/><circle cx="20" cy="51" r="1.1" fill="#E3CCFF"/><circle cx="44" cy="51" r="1.1" fill="#E3CCFF"/>`
    + `<path d="M32 4C45.5 4 53.5 13 53.5 24C53.5 33.5 46 40.5 32 40.5C18 40.5 10.5 33.5 10.5 24C10.5 13 18.5 4 32 4Z" fill="url(#gnr-purple)" stroke="#3D137F" stroke-width="2.4"/>`
    + `<path d="M19 15Q22 10.5 27 12.5Q31 8.5 36.5 11.5Q41 9.5 45 14.5M15.5 22Q19 18.5 23 20.5M41 20.5Q45 18.5 48.5 22" fill="none" stroke="#7B3BD8" stroke-width="1.5" stroke-linecap="round"/>`
    + `<ellipse cx="20" cy="11" rx="5.5" ry="2.8" transform="rotate(-30 20 11)" fill="#fff" opacity=".6"/>`
    + `<ellipse cx="24.5" cy="28.5" rx="5.6" ry="6" fill="#fff" stroke="#3D137F" stroke-width="1.7"/><ellipse cx="39.5" cy="28.5" rx="5.6" ry="6" fill="#fff" stroke="#3D137F" stroke-width="1.7"/>`
    + `<circle cx="26.2" cy="26.8" r="3.4" fill="#1A0838"/><circle cx="41.2" cy="26.8" r="3.4" fill="#1A0838"/><circle cx="25.2" cy="25.6" r="1.3" fill="#fff"/><circle cx="40.2" cy="25.6" r="1.3" fill="#fff"/>`
    + `<path d="M19.5 21Q24 18.5 28.5 20.5M35.5 19Q40 16 44.5 19" fill="none" stroke="#3D137F" stroke-width="1.7" stroke-linecap="round"/>`
    + `<path d="M28.5 36Q30.5 34.5 32.5 36Q34.5 37.5 36.5 36" fill="none" stroke="#3D137F" stroke-width="1.6" stroke-linecap="round"/></g>`,

    // 5. Robo Scout
    `<path d="M32 17V9" stroke="#6B4A06" stroke-width="4.6" stroke-linecap="round"/><path d="M32 17V9" stroke="#D9DCE6" stroke-width="2.2" stroke-linecap="round"/>`
    + `<circle cx="32" cy="7" r="3.8" fill="#FF6A3D" stroke="#6B2A08" stroke-width="1.8"/><circle cx="30.8" cy="5.8" r="1.2" fill="#fff"/>`
    + `<rect x="5" y="28" width="7" height="15" rx="2.5" fill="url(#gnr-gold)" stroke="#7A5508" stroke-width="2"/><rect x="52" y="28" width="7" height="15" rx="2.5" fill="url(#gnr-gold)" stroke="#7A5508" stroke-width="2"/>`
    + `<rect x="10" y="16" width="44" height="40" rx="8" fill="url(#gnr-gold)" stroke="#7A5508" stroke-width="2.4"/>`
    + `<path d="M14.5 26V22.5Q14.5 19.5 18 19.5H29" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity=".7"/>`
    + `<rect x="16" y="23" width="32" height="20" rx="5" fill="url(#gnr-screen)" stroke="#7A5508" stroke-width="1.8"/>`
    + `<rect x="21" y="27" width="7" height="9" rx="3.2" fill="#FFF3A6"/><rect x="36" y="27" width="7" height="9" rx="3.2" fill="#FFF3A6"/>`
    + `<path d="M28 38.5Q32 41 36 38.5" fill="none" stroke="#FFF3A6" stroke-width="1.6" stroke-linecap="round"/>`
    + `<path d="M18 25L26 25L19 40Z" fill="#fff" opacity=".12"/>`
    + `<path d="M26 46.5V51M32 46.5V51M38 46.5V51" stroke="#8A6008" stroke-width="2" stroke-linecap="round"/>`
    + `<circle cx="14.5" cy="51.5" r="1.6" fill="#A9760C"/><circle cx="49.5" cy="51.5" r="1.6" fill="#A9760C"/><circle cx="49.5" cy="20.5" r="1.6" fill="#A9760C"/>`,

    // 6. Goo Drop
    `<path d="M32 4.5C35.5 12 45 21 48.5 31C51 38 50.5 44 47.5 48.5C53 49.5 57.5 51.5 57.5 54.5C57.5 58 52 59 46 59H18C12 59 6.5 58 6.5 54.5C6.5 51.5 11 49.5 16.5 48.5C13.5 44 13 38 15.5 31C19 21 28.5 12 32 4.5Z" fill="url(#gnr-goo)" stroke="#0A6B57" stroke-width="2.4" stroke-linejoin="round"/>`
    + `<path d="M52 12C53.5 15 55 16.5 55 18.5C55 20.2 53.7 21.5 52 21.5C50.3 21.5 49 20.2 49 18.5C49 16.5 50.5 15 52 12Z" fill="url(#gnr-goo)" stroke="#0A6B57" stroke-width="1.8" stroke-linejoin="round"/>`
    + `<path d="M27.5 15Q22 22 20.5 30" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" opacity=".7"/>`
    + `<circle cx="23" cy="44" r="1.8" fill="#fff" opacity=".45"/><circle cx="42" cy="26" r="1.3" fill="#fff" opacity=".5"/><ellipse cx="14" cy="54" rx="4" ry="1.4" fill="#fff" opacity=".45"/>`
    + `<ellipse cx="26" cy="36.5" rx="5" ry="5.8" fill="#fff" stroke="#0A6B57" stroke-width="1.6"/><ellipse cx="38.5" cy="36.5" rx="5" ry="5.8" fill="#fff" stroke="#0A6B57" stroke-width="1.6"/>`
    + `<circle cx="26.8" cy="38" r="3" fill="#06261F"/><circle cx="39.3" cy="38" r="3" fill="#06261F"/><circle cx="25.6" cy="36.6" r="1.3" fill="#fff"/><circle cx="38.1" cy="36.6" r="1.3" fill="#fff"/>`
    + `<ellipse cx="32.3" cy="47" rx="2.8" ry="2.1" fill="#06473A"/>`,

    // 7. Mantis Mind
    `<path d="M28 16C26.5 10 23 6.5 17.5 5.5M36 16C37.5 10 41 6.5 46.5 5.5" fill="none" stroke="#6B2A04" stroke-width="4" stroke-linecap="round"/>`
    + `<path d="M28 16C26.5 10 23 6.5 17.5 5.5M36 16C37.5 10 41 6.5 46.5 5.5" fill="none" stroke="#FFA444" stroke-width="1.7" stroke-linecap="round"/>`
    + `<path d="M27.5 49C22 51 20.5 56 24.5 59L27.5 56C26 54.5 27 52.5 29.5 51.5ZM36.5 49C42 51 43.5 56 39.5 59L36.5 56C38 54.5 37 52.5 34.5 51.5Z" fill="#D9671A" stroke="#6B2A04" stroke-width="1.8" stroke-linejoin="round"/>`
    + `<path d="M11.5 20C13.5 15 20 13.5 25 14.5C28 15 30 15.5 32 15.5C34 15.5 36 15 39 14.5C44 13.5 50.5 15 52.5 20C53.5 28 45.5 41 38 51C35.5 54.5 28.5 54.5 26 51C18.5 41 10.5 28 11.5 20Z" fill="url(#gnr-orange)" stroke="#6B2A04" stroke-width="2.4" stroke-linejoin="round"/>`
    + `<path d="M32 27V43M23 31Q27 37 29.5 46M41 31Q37 37 34.5 46" fill="none" stroke="#B9480A" stroke-width="1.4" stroke-linecap="round" opacity=".7"/>`
    + `<ellipse cx="14" cy="18" rx="9" ry="10.5" transform="rotate(-28 14 18)" fill="url(#gnr-bug)" stroke="#6B2A04" stroke-width="2.2"/><ellipse cx="50" cy="18" rx="9" ry="10.5" transform="rotate(28 50 18)" fill="url(#gnr-bug)" stroke="#6B2A04" stroke-width="2.2"/>`
    + `<g fill="#E39A52" opacity=".5"><circle cx="9.5" cy="22.5" r="1"/><circle cx="12.5" cy="25" r="1"/><circle cx="8" cy="18.5" r="1"/><circle cx="54.5" cy="22.5" r="1"/><circle cx="51.5" cy="25" r="1"/><circle cx="56" cy="18.5" r="1"/></g>`
    + `<circle cx="17.5" cy="20" r="4" fill="#1C0A02"/><circle cx="46.5" cy="20" r="4" fill="#1C0A02"/><circle cx="16.2" cy="18.6" r="1.6" fill="#fff"/><circle cx="45.2" cy="18.6" r="1.6" fill="#fff"/>`
    + `<ellipse cx="10.5" cy="13" rx="2.6" ry="1.6" transform="rotate(-35 10.5 13)" fill="#fff" opacity=".9"/>`
    + `<circle cx="32" cy="20" r="1.6" fill="#FFF0B8" stroke="#8A3A06" stroke-width="1.2"/><circle cx="28.5" cy="23" r="1.4" fill="#FFF0B8" stroke="#8A3A06" stroke-width="1.2"/><circle cx="35.5" cy="23" r="1.4" fill="#FFF0B8" stroke="#8A3A06" stroke-width="1.2"/>`
    + `<path d="M28.5 42Q32 45 35.5 42" fill="none" stroke="#6B2A04" stroke-width="1.7" stroke-linecap="round"/>`,

    // 8. Crystal Sage
    `<path d="M7.8 20L10.8 26L7.8 32L4.8 26Z" fill="#9FCBFF" stroke="#173B85" stroke-width="1.6" stroke-linejoin="round"/><path d="M56.2 38L59.2 43.5L56.2 49L53.2 43.5Z" fill="#9FCBFF" stroke="#173B85" stroke-width="1.6" stroke-linejoin="round"/>`
    + `<path d="M32 4L49 17L40 20H24L15 17Z" fill="#D2E9FF"/><path d="M15 17L24 20L20 38H12Z" fill="#92C4FF"/><path d="M49 17L52 38H44L40 20Z" fill="#2F6ED4"/>`
    + `<path d="M12 38H20L28 50L24 57Z" fill="#4A8BEB"/><path d="M52 38L40 57L36 50L44 38Z" fill="#1F4FAE"/><path d="M24 57L28 50H36L40 57Z" fill="#2D62C6"/>`
    + `<path d="M24 20H40L44 38L36 50H28L20 38Z" fill="url(#gnr-cryst)"/>`
    + `<path d="M24 20H40L44 38L36 50H28L20 38Z" fill="none" stroke="#E2F1FF" stroke-width="1.2" stroke-linejoin="round" opacity=".7"/>`
    + `<path d="M32 4L49 17L52 38L40 57H24L12 38L15 17Z" fill="none" stroke="#173B85" stroke-width="2.4" stroke-linejoin="round"/>`
    + `<path d="M30 8.5L20 16.5L25 17.5Z" fill="#fff" opacity=".7"/>`
    + `<path d="M32 22.5L34 25L32 27.5L30 25Z" fill="#fff"/>`
    + `<path d="M23.2 30.5Q27 35.5 30.8 30.5M33.2 30.5Q37 35.5 40.8 30.5" fill="none" stroke="#0A1F55" stroke-width="2.3" stroke-linecap="round"/>`
    + `<path d="M28.3 40Q32 43.5 35.7 40" fill="none" stroke="#0A1F55" stroke-width="2" stroke-linecap="round"/><ellipse cx="23" cy="37.5" rx="2.4" ry="1.4" fill="#FF8FC8" opacity=".45"/><ellipse cx="41" cy="37.5" rx="2.4" ry="1.4" fill="#FF8FC8" opacity=".45"/>`
    + `<path d="M55 5.5Q55.8 10.2 60 11Q55.8 11.8 55 16.5Q54.2 11.8 50 11Q54.2 10.2 55 5.5Z" fill="#E2F1FF"/>`,

    // 9. Fuzzball
    `<g transform="translate(0 -1)"><ellipse cx="23" cy="56" rx="5.5" ry="3.3" fill="#D8303A" stroke="#6E0A12" stroke-width="2"/><ellipse cx="41" cy="56" rx="5.5" ry="3.3" fill="#D8303A" stroke="#6E0A12" stroke-width="2"/>`
    + `<path d="M32 12.5Q30.7 7.5 41.1 7.6Q41.8 11.6 40.9 14.5Q41.9 9.5 51.2 14.1Q50.1 18 48 20.2Q51.1 16.1 57.6 24.3Q54.8 27.3 52 28.4Q56.5 26.1 58.8 36.2Q55 37.8 52 37.6Q57.1 37.4 54.7 47.5Q50.7 47.3 48 45.8Q52.7 47.9 46.2 56Q42.6 54 40.9 51.5Q44.2 55.4 34.8 59.9Q32.5 56.5 32 53.5Q33.3 58.5 22.9 58.4Q22.2 54.4 23.1 51.5Q22.1 56.5 12.8 51.9Q13.9 48 16 45.8Q12.9 49.9 6.4 41.7Q9.2 38.7 12 37.6Q7.5 39.9 5.2 29.8Q9 28.2 12 28.4Q6.9 28.6 9.3 18.5Q13.3 18.7 16 20.2Q11.3 18.1 17.8 10Q21.4 12 23.1 14.5Q19.8 10.6 29.2 6.1Q31.5 9.5 32 12.5Z" fill="url(#gnr-red)" stroke="#6E0A12" stroke-width="2.4" stroke-linejoin="round"/>`
    + `<ellipse cx="21" cy="19" rx="5.5" ry="2.8" transform="rotate(-35 21 19)" fill="#fff" opacity=".55"/>`
    + `<ellipse cx="25" cy="31" rx="6.4" ry="7.4" fill="#fff" stroke="#6E0A12" stroke-width="1.8"/><ellipse cx="39.5" cy="31" rx="6.4" ry="7.4" fill="#fff" stroke="#6E0A12" stroke-width="1.8"/>`
    + `<circle cx="26.5" cy="32.5" r="3.9" fill="#1F0306"/><circle cx="38" cy="32.5" r="3.9" fill="#1F0306"/><circle cx="25" cy="30.8" r="1.6" fill="#fff"/><circle cx="36.5" cy="30.8" r="1.6" fill="#fff"/>`
    + `<path d="M19.5 21.5Q24 19 28.5 21M36 21Q40.5 19 45 21.5" fill="none" stroke="#6E0A12" stroke-width="1.8" stroke-linecap="round"/>`
    + `<path d="M24.5 41.5Q32 43.5 39.5 41.5Q38 49.5 32 49.5Q26 49.5 24.5 41.5Z" fill="#3A0408" stroke="#6E0A12" stroke-width="1.6" stroke-linejoin="round"/><ellipse cx="32" cy="47.3" rx="3.6" ry="1.6" fill="#FF8A8A"/>`
    + `<path d="M27.2 42.4L28.6 45.6L30.1 42.9ZM33.9 42.9L35.4 45.6L36.8 42.4Z" fill="#fff"/></g>`,
  ],
};
