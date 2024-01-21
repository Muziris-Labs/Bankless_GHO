import HomeNav from "@/components/navBar/HomeNav";
import Footer from "@/components/layout/home/Footer";

export const metadata = {
  title: "B-Wallet",
  description: "By Bankless DAO",
};

export default function RootLayout({ children }) {
  return (
    <>
      <HomeNav />
      {children}
      <Footer />
    </>
  );
}
