// Tiny shared script: scroll-reveal + active nav + year.
document.addEventListener('DOMContentLoaded',()=>{
  const io=new IntersectionObserver((entries)=>{
    entries.forEach(e=>{ if(e.isIntersecting){ e.target.classList.add('in'); io.unobserve(e.target); } });
  },{threshold:0.1,rootMargin:'0px 0px -40px 0px'});
  document.querySelectorAll('.reveal').forEach(el=>io.observe(el));

  const path=location.pathname.split('/').pop()||'index.html';
  document.querySelectorAll('.nav-links a[data-page]').forEach(a=>{
    if(a.dataset.page===path) a.classList.add('active');
  });

  const y=document.querySelector('[data-year]');
  if(y) y.textContent=new Date().getFullYear();
});
