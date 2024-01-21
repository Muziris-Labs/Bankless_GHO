"use client";

import { Step } from "@material-tailwind/react";
import {
  UserIcon,
  ShieldCheckIcon,
  LockClosedIcon,
} from "@heroicons/react/24/outline";

const StepperItem = ({ activeStep, setActiveStep, stepNo, stepDes }) => {
  const iconClass = `cursor-pointer h-5 w-5 ${
    activeStep >= stepNo ? "text-black" : "text-white"
  }`;

  const icons = [
    <UserIcon key={1} className={iconClass} />,
    <LockClosedIcon key={2} className={iconClass} />,
    <ShieldCheckIcon key={3} className={iconClass} />,
  ];
  return (
    <Step
      onClick={() => setActiveStep(3)}
      className={`cursor-pointer ${
        activeStep >= stepNo ? "bg-white" : "bg-gray-700"
      }`}
    >
      {icons[stepNo]}

      <div className="absolute -bottom-[4.5rem] w-max text-center">
        <p className={activeStep === stepNo ? "text-white" : "text-gray-500"}>
          {`Step ${stepNo + 1}`}
        </p>

        <p
          className={`font-normal ${
            activeStep === stepNo ? "text-white" : "text-gray-500"
          }`}
        >
          {stepDes}
        </p>
      </div>
    </Step>
  );
};

export default StepperItem;
