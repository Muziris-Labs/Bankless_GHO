import { createSlice } from "@reduxjs/toolkit";

const setupSlice = createSlice({
  name: "setup",
  initialState: {
    activeStep: 0,
  },

  reducers: {
    setActiveStep: (state, action) => {
      state.activeStep = action.payload;
    },
  },
});

export const { setActiveStep } = setupSlice.actions;

export default setupSlice.reducer;
