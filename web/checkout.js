window.hmsCheckout = async function (jsonOptions) {
  if (!window.Razorpay) {
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = resolve;
      script.onerror = () => { script.remove(); reject(new Error('Unable to load checkout')); };
      document.head.appendChild(script);
    });
  }
  return new Promise((resolve, reject) => {
    const options = JSON.parse(jsonOptions);
    options.handler = resolve;
    options.modal = { ondismiss: () => reject(new Error('Checkout closed')) };
    const checkout = new window.Razorpay(options);
    checkout.on('payment.failed', response => reject(new Error(response.error.description)));
    checkout.open();
  });
};
