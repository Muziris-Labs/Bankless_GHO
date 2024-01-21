import Tokens from "@/components/layout/dashboard/home/tokens/Tokens";
import Actions from "@/components/layout/dashboard/home/actions/Actions";
import Portfolio from "@/components/layout/dashboard/home/portfolio/Portfolio";
import Transactions from "@/components/layout/dashboard/home/transactions/Transactions";

export const metadata = {
  title: "B-Wallet | Dashboard",
  description: "By Bankless DAO",
};

export default function Dashboard() {
  return (
    <article className="flex gap-5">
      <section className="w-full">
        <Portfolio />
        <Tokens />
      </section>

      <aside className="w-full max-w-sm space-y-6">
        <Actions />
        <Transactions />
      </aside>
    </article>
  );
}
