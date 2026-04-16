// API Configuration
const API_CONFIG = {
    BASE_URL: 'https://mukunda-jamar-katel-kishansathi.onrender.com',  
    ENDPOINTS: {
        AUTH: {
            LOGIN: '/api/auth/login/',
            LOGOUT: '/api/auth/logout/',
        },
        ADMIN: {
            STATS: '/api/admin/stats/',
            ACTIVITY: '/api/admin/activity/',
            USERS: '/api/admin/users/',
            PRODUCTS: '/api/admin/products/',
            POSTS: '/api/admin/posts/',
            DOCTORS: '/api/admin/doctors/',

            
        }
    }
};

// Storage keys
const STORAGE_KEYS = {
    AUTH_TOKEN: 'admin_auth_token',
    USER_DATA: 'admin_user_data',
};

// Helper function to get auth token
function getAuthToken() {
    return localStorage.getItem(STORAGE_KEYS.AUTH_TOKEN);
}

// Helper function to set auth token
function setAuthToken(token) {
    localStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, token);
}

// Helper function to clear auth data
function clearAuthData() {
    localStorage.removeItem(STORAGE_KEYS.AUTH_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.USER_DATA);
}

// Helper function to check if user is logged in
function isLoggedIn() {
    return !!getAuthToken();
}

// Helper function to redirect to login if not authenticated
function checkAuth() {
    if (!isLoggedIn()) {
        window.location.href = 'login.html';
        return false;
    }
    return true;
}

// API call helper with authentication
async function apiCall(endpoint, options = {}) {
    const token = getAuthToken();
    
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            ...(token && { 'Authorization': `Token ${token}` }),
        },
    };

    const finalOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers,
        },
    };

    try {
        const response = await fetch(`${API_CONFIG.BASE_URL}${endpoint}`, finalOptions);
        
        // Handle unauthorized
        if (response.status === 401) {
            clearAuthData();
            window.location.href = 'login.html';
            throw new Error('Unauthorized');
        }

        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.message || data.detail || 'API request failed');
        }

        return data;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Format date helper
function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
    if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    
    return date.toLocaleDateString();
}

// Show error message
function showError(message) {
    alert(message);
}

// Show success message
function showSuccess(message) {
    alert(message);
}

// Logout function
function logout() {
    if (confirm('Are you sure you want to logout?')) {
        clearAuthData();
        window.location.href = 'login.html';
    }
}
