"use client";

import { CheckIcon } from "@heroicons/react/24/outline";
import { Checkbox } from "@material-tailwind/react";

const CheckBox = () => {
  return (
    <div>
      <div>
        <Checkbox
          icon={
            <CheckIcon className="h-11/12 mx-auto w-11/12 text-purple-300" />
          }
          checked={true}
          readOnly
          ripple
          label={
            <p className="text-xl text-white lg:text-2xl xl:text-3xl">
              100% Self Custody
            </p>
          }
          className="h-8 w-8 shadow shadow-white/30 lg:h-9 lg:w-9 xl:h-10 xl:w-10"
        />
      </div>

      <div>
        <Checkbox
          icon={
            <CheckIcon className="h-11/12 mx-auto w-11/12 text-purple-300" />
          }
          checked={true}
          readOnly
          ripple
          label={
            <p className="text-xl text-white lg:text-2xl  xl:text-3xl">
              100% Protection
            </p>
          }
          className="h-8 w-8 shadow shadow-white/30 lg:h-9 lg:w-9 xl:h-10 xl:w-10"
        />
      </div>
    </div>
  );
};
export default CheckBox;
