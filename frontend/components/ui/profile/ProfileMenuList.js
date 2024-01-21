"use client";

import {
  ArrowLeftOnRectangleIcon,
  Cog8ToothIcon,
  UserCircleIcon,
} from "@heroicons/react/24/outline";
import { MenuList } from "@material-tailwind/react";

import ProfileMenuItem from "./ProfileMenuItem";
import { useDisconnect } from "wagmi";
import { setSignature } from "@/redux/slice/walletSlice";
import { useDispatch, useSelector } from "react-redux";
import { handleLoginModal, handleRoleModal } from "@/redux/slice/modalSlice";

const ProfileMenuList = () => {
  const { disconnect } = useDisconnect();
  const signature = useSelector((state) => state.wallet.signature);
  const dispatch = useDispatch();
  return (
    <MenuList className="min-w-[172px] border-gray-500 bg-gray-900 p-0">
      {!signature && (
        <ProfileMenuItem
          label="Sign Message"
          icon={<Cog8ToothIcon className="h-4 w-4" />}
          onClick={() => {
            dispatch(handleLoginModal());
          }}
          labelStyle={"text-white"}
        />
      )}
      {signature && (
        <ProfileMenuItem
          label="Change Role"
          icon={<UserCircleIcon className="h-4 w-4 text-white" />}
          onClick={() => {
            dispatch(handleRoleModal());
          }}
          labelStyle={"text-white"}
        />
      )}
      <ProfileMenuItem
        label="Disconnect"
        icon={<ArrowLeftOnRectangleIcon className="h-4 w-4 text-red-500" />}
        onClick={() => {
          dispatch(setSignature(null));
          disconnect();
        }}
      />
    </MenuList>
  );
};

export default ProfileMenuList;
