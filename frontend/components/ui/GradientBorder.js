const GradientBorder = ({ children }) => {
  return (
    <div className={"mx-auto w-fit rounded-full bg-gradient-primary p-1"}>
      {children}
    </div>
  );
};

export default GradientBorder;
