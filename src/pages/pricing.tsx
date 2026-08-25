import React from 'react'
import Head from 'next/head'
import Link from 'next/link'

export default function Pricing() {
  return (
    <>
      <Head><title>Pricing & Maintenance Plans | Acme Home Services</title></Head>
      <header style={{ background: '#0F172A', borderBottom: '1px solid #1E293B', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#fff' }}>
        <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#38BDF8' }}>🛠️ Acme Home Services</div>
        <nav style={{ display: 'flex', gap: '1.5rem', fontSize: '0.9375rem', fontWeight: 600 }}>
          <Link href="/" style={{ color: '#94A3B8', textDecoration: 'none' }}>Home</Link>
          <Link href="/services" style={{ color: '#94A3B8', textDecoration: 'none' }}>Services</Link>
          <Link href="/about" style={{ color: '#94A3B8', textDecoration: 'none' }}>About</Link>
          <Link href="/pricing" style={{ color: '#38BDF8', textDecoration: 'none' }}>Pricing</Link>
          <Link href="/contact" style={{ color: '#94A3B8', textDecoration: 'none' }}>Contact</Link>
        </nav>
      </header>
      <main style={{ fontFamily: 'system-ui, sans-serif', background: '#020617', color: '#F8FAFC', minHeight: '80vh', padding: '4rem 2rem' }}>
        <div style={{ maxWidth: '900px', margin: '0 auto', textAlign: 'center' }}>
          <h1 style={{ fontSize: '2.5rem', fontWeight: 900, marginBottom: '1rem', color: '#38BDF8' }}>Transparent Upfront Pricing</h1>
          <p style={{ color: '#94A3B8', fontSize: '1.125rem', marginBottom: '3rem' }}>No hidden fees or unexpected hourly surcharges.</p>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1.5rem', textAlign: 'left' }}>
            <div style={{ background: '#0F172A', border: '1px solid #1E293B', borderRadius: '12px', padding: '2rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Standard Diagnostic</h3>
              <div style={{ fontSize: '2rem', fontWeight: 900, color: '#38BDF8', marginBottom: '1rem' }}>$89</div>
              <p style={{ color: '#94A3B8', fontSize: '0.875rem' }}>Full home plumbing or HVAC inspection waived with repair.</p>
            </div>
            <div style={{ background: '#0F172A', border: '2px solid #38BDF8', borderRadius: '12px', padding: '2rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Home Protection Plan</h3>
              <div style={{ fontSize: '2rem', fontWeight: 900, color: '#38BDF8', marginBottom: '1rem' }}>$19/mo</div>
              <p style={{ color: '#94A3B8', fontSize: '0.875rem' }}>2 annual tune-ups, 15% discount on all repairs, priority scheduling.</p>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}
