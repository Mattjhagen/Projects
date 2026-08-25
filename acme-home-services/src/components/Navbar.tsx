import Link from 'next/link';

export default function Navbar() {
  return (
    <nav className="bg-amber-800 text-white shadow-lg">
      <div className="container mx-auto px-4 py-4">
        <div className="flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold hover:text-amber-200 transition">
            Acme Home Services
          </Link>
          
          <div className="hidden md:flex space-x-6">
            <Link href="/about" className="hover:text-amber-200 transition">About Us</Link>
            <Link href="/services" className="hover:text-amber-200 transition">Services</Link>
            <Link href="/pricing" className="hover:text-amber-200 transition">Pricing</Link>
            <Link href="/contact" className="hover:text-amber-200 transition">Contact</Link>
          </div>
        </div>
      </div>
    </nav>
  );
}
