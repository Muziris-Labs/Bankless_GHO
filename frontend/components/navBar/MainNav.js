"use client";

import { useState, useEffect } from "react";
import { Navbar, IconButton } from "@material-tailwind/react";
import { Bars3Icon, XMarkIcon } from "@heroicons/react/24/outline";

import Logo from "../Logo";
import NavList from "./NavList";
import MobileNav from "./MobileNav";

const MainNav = ({
  navList,
  btn,
  mobileBtn,
  style,
  maxWidth,
  size,
  itemStyle,
  activeStyle,
  nonActiveStyle,
}) => {
  const [openNav, setOpenNav] = useState(false);

  useEffect(() => {
    window.addEventListener(
      "resize",
      () => window.innerWidth >= 960 && setOpenNav(false),
    );
  }, []);

  return (
    <Navbar
      className={`sticky top-0 z-40 h-max max-w-full rounded-none border-none px-4 py-2 backdrop-blur-sm lg:px-8 lg:py-3 ${style}`}
    >
      <div
        className={`mx-auto flex items-center justify-between text-gray-300 ${
          maxWidth || "max-w-6xl"
        }`}
      >
        <Logo />

        <div className="mr-4 hidden lg:block">
          <NavList
            list={navList}
            size={size}
            itemStyle={itemStyle}
            activeStyle={activeStyle}
            nonActiveStyle={nonActiveStyle}
          />
        </div>

        <div className="flex items-center gap-4">
          {btn}

          <IconButton
            variant="text"
            className="ml-auto h-6 w-6 text-inherit hover:bg-transparent focus:bg-transparent active:bg-transparent lg:hidden"
            ripple={false}
            onClick={() => setOpenNav(!openNav)}
          >
            {openNav ? (
              <XMarkIcon className="h-6 w-6 text-white" />
            ) : (
              <Bars3Icon className="h-6 w-6 text-white" />
            )}
          </IconButton>
        </div>
      </div>

      <MobileNav openNav={openNav} navList={navList}>
        {mobileBtn}
      </MobileNav>
    </Navbar>
  );
};

export default MainNav;
