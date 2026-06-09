export default defineNuxtConfig({
  app: {
    baseURL: '/',
    head: {
      htmlAttrs: { lang: 'en' },
      link: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:ital,wght@0,300;0,400;0,500;0,600;1,400&family=Barlow+Condensed:wght@300;400;600;700;900&display=swap' }
      ]
    }
  },
  css: ['~/assets/main.css'],
})
