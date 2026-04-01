import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Orders from './pages/Orders';
import Shoppers from './pages/Shoppers';
import Customers from './pages/Customers';
import Markets from './pages/Markets';
import Earnings from './pages/Earnings';
import Settings from './pages/Settings';
import AddUser from './pages/AddUser';
import Login from './pages/Login';
import AddMarket from './pages/AddMarket';

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Auth routes — no sidebar/topbar */}
          <Route path="login" element={<Login />} />

          {/* App shell — protected */}
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="orders" element={<Orders />} />
            <Route path="shoppers" element={<Shoppers />} />
            <Route path="customers" element={<Customers />} />
            <Route path="markets" element={<Markets />} />
            <Route path="markets/add" element={<AddMarket />} />
            <Route path="earnings" element={<Earnings />} />
            <Route path="settings" element={<Settings />} />
            <Route path="settings/users/add" element={<AddUser />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
