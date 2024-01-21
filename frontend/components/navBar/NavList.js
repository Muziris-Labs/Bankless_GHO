import NavItem from "./NavItem";

const NavList = ({ list, size, itemStyle, activeStyle, nonActiveStyle }) => {
  return (
    <ul className="prevent-select mb-4 mt-2 flex flex-col gap-2 font-grotesque lg:mb-0 lg:mt-0 lg:flex-row lg:items-center">
      {list &&
        list.map((item) => (
          <NavItem
            key={item.name}
            name={item.name}
            href={item.href}
            active={item.active}
            size={size}
            itemStyle={itemStyle}
            activeStyle={activeStyle}
            nonActiveStyle={nonActiveStyle}
          />
        ))}
    </ul>
  );
};

export default NavList;
