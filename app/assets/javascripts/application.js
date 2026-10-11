document.addEventListener("submit", (event) => {
  const form = event.target;
  const confirmation = form.dataset.turboConfirm || form.querySelector("[data-turbo-confirm]")?.dataset.turboConfirm;
  if (confirmation && !window.confirm(confirmation)) event.preventDefault();
});
