import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-5xl font-bold text-white mb-8">
          React + Tailwind CSS
        </h1>
        <p className="text-gray-400 mb-8 text-lg">
          Vite + SWC + TypeScript + Tailwind CSS v4
        </p>
        <div className="bg-gray-800 rounded-xl p-8 shadow-2xl">
          <button
            onClick={() => setCount((c) => c + 1)}
            className="bg-primary hover:bg-primary-dark text-white font-semibold py-3 px-8 rounded-lg transition-colors duration-200 text-lg"
          >
            Count: {count}
          </button>
        </div>
        <p className="text-gray-500 mt-8 text-sm">
          Edit <code className="text-primary">src/App.tsx</code> and save to test HMR
        </p>
      </div>
    </div>
  );
}

export default App;
