import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Auth
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

// Customer
import '../../features/customer/customer_shell.dart';
import '../../features/customer/home/presentation/customer_home_screen.dart';
import '../../features/customer/store/presentation/store_screen.dart';
import '../../features/customer/store/presentation/product_detail_screen.dart';
import '../../features/customer/store/presentation/cart_screen.dart';
import '../../features/customer/store/presentation/checkout_screen.dart';
import '../../features/customer/store/presentation/order_success_screen.dart';
import '../../features/customer/services/presentation/services_screen.dart';
import '../../features/customer/services/presentation/service_request_screen.dart';
import '../../features/customer/services/presentation/service_success_screen.dart';
import '../../features/customer/profile/presentation/customer_profile_screen.dart';
import '../../features/customer/profile/presentation/my_orders_screen.dart';
import '../../features/customer/profile/presentation/order_detail_screen.dart';
import '../../features/customer/profile/presentation/my_devices_screen.dart';

// Manager
import '../../features/manager/manager_shell.dart';
import '../../features/manager/dashboard/presentation/manager_dashboard_screen.dart';
import '../../features/manager/orders/presentation/manager_orders_screen.dart';
import '../../features/manager/orders/presentation/manager_order_detail_screen.dart';
import '../../features/manager/technicians/presentation/technicians_screen.dart';
import '../../features/manager/technicians/presentation/add_technician_screen.dart';
import '../../features/manager/technicians/presentation/manager_technician_detail_screen.dart';
import '../../features/manager/products/presentation/manage_products_screen.dart';
import '../../features/manager/products/presentation/product_form_screen.dart';

// Technician
import '../../features/technician/technician_shell.dart';
import '../../features/technician/tasks/presentation/tech_tasks_screen.dart';
import '../../features/technician/tasks/presentation/tech_task_detail_screen.dart';
import '../../features/technician/profile/presentation/tech_profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ========== AUTH ==========
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ========== CUSTOMER ==========
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/customer/home',
            builder: (_, __) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/customer/store',
            builder: (_, __) => const StoreScreen(),
          ),
          GoRoute(
            path: '/customer/services',
            builder: (_, __) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/customer/profile',
            builder: (_, __) => const CustomerProfileScreen(),
          ),
        ],
      ),
      // Customer routes outside shell (full-screen)
      GoRoute(
        path: '/customer/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/customer/cart', builder: (_, __) => const CartScreen()),
      GoRoute(
        path: '/customer/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/customer/order-success',
        builder: (_, __) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: '/customer/service-request/:id',
        builder: (_, state) =>
            ServiceRequestScreen(serviceTypeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer/service-success',
        builder: (_, __) => const ServiceSuccessScreen(),
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (_, __) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/customer/order/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer/devices',
        builder: (_, __) => const MyDevicesScreen(),
      ),

      // ========== MANAGER ==========
      ShellRoute(
        builder: (_, __, child) => ManagerShell(child: child),
        routes: [
          GoRoute(
            path: '/manager/dashboard',
            builder: (_, __) => const ManagerDashboardScreen(),
          ),
          GoRoute(
            path: '/manager/orders',
            builder: (_, __) => const ManagerOrdersScreen(),
          ),
          GoRoute(
            path: '/manager/technicians',
            builder: (_, __) => const TechniciansScreen(),
          ),
          GoRoute(
            path: '/manager/products',
            builder: (_, __) => const ManageProductsScreen(),
          ),
        ],
      ),
      // Manager routes outside shell
      GoRoute(
        path: '/manager/order/:id',
        builder: (_, state) =>
            ManagerOrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/manager/add-technician',
        builder: (_, __) => const AddTechnicianScreen(),
      ),
      GoRoute(
        path: '/manager/technicians/:id',
        builder: (_, state) => ManagerTechnicianDetailScreen(
          technicianId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/manager/product/form',
        builder: (_, state) =>
            ProductFormScreen(productId: state.extra as String?),
      ),

      // ========== TECHNICIAN ==========
      ShellRoute(
        builder: (_, __, child) => TechnicianShell(child: child),
        routes: [
          GoRoute(
            path: '/technician/tasks',
            builder: (_, __) => const TechTasksScreen(),
          ),
          GoRoute(
            path: '/technician/profile',
            builder: (_, __) => const TechProfileScreen(),
          ),
        ],
      ),
      // Technician routes outside shell
      GoRoute(
        path: '/technician/task/:id',
        builder: (_, state) =>
            TechTaskDetailScreen(assignmentId: state.pathParameters['id']!),
      ),
    ],
  );
});
