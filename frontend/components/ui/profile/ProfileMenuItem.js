import { Button, MenuItem } from "@material-tailwind/react";

const ProfileMenuItem = ({ icon, label, onClick, labelStyle }) => {
  return (
    <Button
      className="flex w-full items-center justify-center gap-2 bg-transparent p-3 hover:bg-gray-800 active:bg-gray-800"
      onClick={onClick}
    >
      {icon || null}

      <div className={"text-red-500 " + labelStyle}>{label}</div>
    </Button>
  );
};

export default ProfileMenuItem;
