/* ===================================================================
 * RCF 1.0.0 - Main JS
 *
 * ------------------------------------------------------------------- */

; (function ($) {
  'use strict'

  const cfg = {
    scrollDuration: 800, // smoothscroll duration
    mailChimpURL: '', // mailchimp url
  }
  const $WIN = $(window)

  // Add the User Agent to the <html>
  // will be used for IE10/IE11 detection (Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0; rv:11.0))
  const doc = document.documentElement
  doc.setAttribute('data-useragent', navigator.userAgent)

  /* Preloader
   * -------------------------------------------------- */
  const ssPreloader = function () {
    $('html').addClass('ss-preload')

    $WIN.on('load', function () {
      // force page scroll position to top at page refresh
      // $('html, body').animate({ scrollTop: 0 }, 'normal');

      // will first fade out the loading animation
      $('#loader').fadeOut('slow', function () {
        // will fade out the whole DIV that covers the website.
        $('#preloader').delay(300).fadeOut('slow')
      })

      // for hero content animations
      $('html').removeClass('ss-preload')
      $('html').addClass('ss-loaded')
    })
  }

  /* Mobile Menu
   * ---------------------------------------------------- */
  const ssMobileMenu = function () {
    const toggleButton = $('.header-menu-toggle')
    const nav = $('.header-nav-wrap')

    toggleButton.on('click', function (event) {
      event.preventDefault()

      toggleButton.toggleClass('is-clicked')
      nav.slideToggle()
    })

    if (toggleButton.is(':visible')) nav.addClass('mobile')

    $WIN.on('resize', function () {
      if (toggleButton.is(':visible')) nav.addClass('mobile')
      else nav.removeClass('mobile')
    })

    nav.find('a').on('click', function () {
      if (nav.hasClass('mobile')) {
        toggleButton.toggleClass('is-clicked')
        nav.slideToggle()
      }
    })
  }

  /* Alert Boxes
   * ------------------------------------------------------ */
  const ssAlertBoxes = function () {
    $('.alert-box').on('click', '.alert-box__close', function () {
      $(this).parent().fadeOut(500)
    })
  }

  /* Smooth Scrolling
   * ------------------------------------------------------ */
  const ssSmoothScroll = function () {
    $('.smoothscroll').on('click', function (e) {
      const target = this.hash
      const $target = $(target)

      e.preventDefault()
      e.stopPropagation()

      $('html, body')
        .stop()
        .animate(
          {
            scrollTop: $target.offset().top,
          },
          cfg.scrollDuration,
          'swing'
        )
        .promise()
        .done(function () {
          // check if menu is open
          if ($('body').hasClass('menu-is-open')) {
            $('.header-menu-toggle').trigger('click')
          }

          window.location.hash = target
        })
    })
  }

  /* Back to Top
   * ------------------------------------------------------ */
  const ssBackToTop = function () {
    const pxShow = 500
    const $goTopButton = $('.ss-go-top')

    // Show or hide the button
    if ($(window).scrollTop() >= pxShow) $goTopButton.addClass('link-is-visible')

    $(window).on('scroll', function () {
      if ($(window).scrollTop() >= pxShow) {
        if (!$goTopButton.hasClass('link-is-visible')) $goTopButton.addClass('link-is-visible')
      } else {
        $goTopButton.removeClass('link-is-visible')
      }
    })
  }

  /* Set current year in footer
   * ------------------------------------------------------ */
  const ssSetYear = function () {
    try {
      const els = document.querySelectorAll('.ss-year')
      const y = new Date().getFullYear()
      els.forEach(function (el) {
        el.textContent = y
      })
    } catch (err) {
      // fail silently on older browsers
    }
  }

    /* Initialize
     * ------------------------------------------------------ */
    ; (function ssInit() {
      ssPreloader()
      ssMobileMenu()
      ssAlertBoxes()
      ssSmoothScroll()
      ssBackToTop()
      ssSetYear()
      ssContactForm()
    })()
})(jQuery)

/* Contact Form
 * ------------------------------------------------------ */
const ssContactForm = function () {
  const form = document.getElementById('contactForm')
  const submitBtn = document.getElementById('submit')

  if (!form) return

  form.addEventListener('submit', async function (e) {
    e.preventDefault()

    // Disable submit button
    submitBtn.disabled = true

    // Get form data
    const formData = {
      cName: document.getElementById('cName').value,
      cEmail: document.getElementById('cEmail').value,
      cMessage: document.getElementById('cMessage').value,
    }

    // API Gateway URL - REPLACE THIS WITH YOUR ACTUAL URL
    const apiURL = 'YOUR_API_GATEWAY_URL_HERE'

    if (apiURL === 'YOUR_API_GATEWAY_URL_HERE') {
      alert('Please configure the API Gateway URL in js/main.js')
      submitBtn.disabled = false
      return
    }

    try {
      const response = await fetch(apiURL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // Show success message
      alert('Message sent successfully!')
      form.reset()
    } catch (error) {
      console.error('Error:', error)
      alert('Something went wrong. Please try again.')
    } finally {
      // Re-enable button regardless of success or failure
      submitBtn.disabled = false
    }
  })
}
