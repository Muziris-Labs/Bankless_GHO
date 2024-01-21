import Link from "next/link";

const NavItem = ({
  name,
  href,
  active,
  size = "text-xl",
  itemStyle = "rounded-lg",
  activeStyle = "text-white",
  nonActiveStyle = "text-gray-500 md:hover:text-white md:hover:bg-gray-700",
}) => {
  return (
    <li
      className={`px-4 py-1.5 font-normal transition-colors ${itemStyle} ${size}  ${
        active ? activeStyle : nonActiveStyle
      }`}
    >
      <Link href={href} className="flex flex-1">
        {name}
      </Link>
    </li>
  );
};

export default NavItem;
