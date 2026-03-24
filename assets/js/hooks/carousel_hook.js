const CarouselHook = {
  mounted() {
    this.carousel = this.el;
    this.track = this.carousel.firstElementChild;
    this.paused = false;
    this.pauseTimer = null;
    this.rafId = null;

    // Mobile: swipe-only, no auto-scroll. Also respect reduced motion.
    if (window.innerWidth < 640 || matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    // Duplicate cards for seamless looping
    this.track.innerHTML += this.track.innerHTML;

    this.speed = 0.5; // px per frame

    this.step = () => {
      if (!this.paused) {
        this.carousel.scrollLeft += this.speed;
        // Reset seamlessly when we've scrolled past the original set
        const halfWidth = this.track.scrollWidth / 2;
        if (this.carousel.scrollLeft >= halfWidth) {
          this.carousel.scrollLeft -= halfWidth;
        }
      }
      this.rafId = requestAnimationFrame(this.step);
    };

    // Start after 2s delay
    this.startTimer = setTimeout(() => {
      this.rafId = requestAnimationFrame(this.step);
    }, 2000);

    this.pauseAutoScroll = () => {
      this.paused = true;
      clearTimeout(this.pauseTimer);
      this.pauseTimer = setTimeout(() => { this.paused = false; }, 3000);
    };

    this.carousel.addEventListener("pointerdown", this.pauseAutoScroll);
    this.carousel.addEventListener("wheel", this.pauseAutoScroll, { passive: true });
    this.carousel.addEventListener("mouseenter", () => { this.paused = true; });
    this.carousel.addEventListener("mouseleave", () => {
      clearTimeout(this.pauseTimer);
      this.pauseTimer = setTimeout(() => { this.paused = false; }, 1000);
    });
  },

  destroyed() {
    clearTimeout(this.startTimer);
    clearTimeout(this.pauseTimer);
    if (this.rafId) cancelAnimationFrame(this.rafId);
  }
};

export default CarouselHook;
