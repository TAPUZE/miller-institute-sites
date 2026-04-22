// Tiny shared script: scroll-reveal + active nav + year + mobile nav toggle.
document.addEventListener('DOMContentLoaded',()=>{
  const io=new IntersectionObserver((entries)=>{
    entries.forEach(e=>{ if(e.isIntersecting){ e.target.classList.add('in'); io.unobserve(e.target); } });
  },{threshold:0.1,rootMargin:'0px 0px -40px 0px'});
  document.querySelectorAll('.reveal').forEach(el=>io.observe(el));

  const path=location.pathname.split('/').pop()||'index.html';
  document.querySelectorAll('.nav-links a[data-page]').forEach(a=>{
    if(a.dataset.page===path) a.classList.add('active');
  });

  document.querySelectorAll('[data-year]').forEach(y=>{ y.textContent=new Date().getFullYear(); });

  // Mobile hamburger: auto-inject toggle into every .site-nav
  document.querySelectorAll('nav.site-nav').forEach(nav=>{
    const container=nav.querySelector('.container');
    const links=nav.querySelector('.nav-links');
    if(!container||!links||nav.querySelector('.nav-toggle')) return;
    const btn=document.createElement('button');
    btn.className='nav-toggle';
    btn.type='button';
    btn.setAttribute('aria-label','Toggle menu');
    btn.setAttribute('aria-expanded','false');
    btn.innerHTML='<span></span><span></span><span></span>';
    container.appendChild(btn);
    btn.addEventListener('click',()=>{
      const open=nav.classList.toggle('nav-open');
      btn.setAttribute('aria-expanded',open?'true':'false');
      document.body.classList.toggle('nav-locked',open);
    });
    links.querySelectorAll('a').forEach(a=>a.addEventListener('click',()=>{
      nav.classList.remove('nav-open');
      btn.setAttribute('aria-expanded','false');
      document.body.classList.remove('nav-locked');
    }));
    window.addEventListener('resize',()=>{
      if(window.innerWidth>820&&nav.classList.contains('nav-open')){
        nav.classList.remove('nav-open');
        btn.setAttribute('aria-expanded','false');
        document.body.classList.remove('nav-locked');
      }
    });
  });
});

