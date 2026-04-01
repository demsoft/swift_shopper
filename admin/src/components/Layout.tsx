import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import TopBar from './TopBar';

export default function Layout() {
  return (
    <div className="bg-surface text-on-surface antialiased">
      <Sidebar />
      <div className="ml-64 min-h-screen">
        <TopBar />
        <main className="pt-16">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
