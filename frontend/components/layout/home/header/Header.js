import HeaderBtn from "./HeaderBtn";

const Header = () => {
  return (
    <header className="mx-4 space-y-12 pt-32 text-center md:mx-0 md:pt-36">
      <div className="space-y-6">
        <h1 className="font-clash-display text-4xl font-medium sm:text-6xl md:text-7xl lg:text-8xl">
          #BankOnChain
        </h1>

        <p className="mx-auto max-w-[50ch] text-base font-medium leading-normal md:text-lg lg:text-xl">
          Unlock the Power of Web3 with Bankless Wallet: Seamlessly Connect,
          Pay, and Explore with Extraordinary Features!
        </p>
      </div>

      <HeaderBtn />
    </header>
  );
};

export default Header;
