import React from 'react'
import Head from 'next/head'
import Link from 'next/link'

export default function About() {
  return (
    <>
      <Head><title>About Us | Acme Home Services</title></Head>
      <header style={{ background: '#0F172A', borderBottom: '1px solid #1E293B', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#fff' }}>
        <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#38BDF8' }}>🛠️ Acme Home Services</div>
        <nav style={{ display: 'flex', gap: '1.5rem', fontSize: '0.9375rem', fontWeight: 600 }}>
          <Link href="/" style={{ color: '#94A3B8', textDecoration: 'none' }}>Home</Link>
          <Link href="/services" style={{ color: '#94A3B8', textDecoration: 'none' }}>Services</Link>
          <Link href="/about" style={{ color: '#38BDF8', textDecoration: 'none' }}>About</Link>
          <Link href="/pricing" style={{ color: '#94A3B8', textDecoration: 'none' }}>Pricing</Link>
          <Link href="/contact" style={{ color: '#94A3B8', textDecoration: 'none' }}>Contact</Link>
        </nav>
      </header>
      <main style={{ fontFamily: 'system-ui, sans-serif', background: '#020617', color: '#F8FAFC', minHeight: '80vh', padding: '4rem 2rem' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto' }}>
          <h1 style={{ fontSize: '2.5rem', fontWeight: 900, marginBottom: '1rem', color: '#38BDF8' }}>About Acme Home Services</h1>
          <p style={{ color: '#94A3B8', fontSize: '1.125rem', lineHeight: 1.8, marginBottom: '1.5rem' }}>
            Founded in Chicago, Acme Home Services has delivered reliable residential plumbing, heating, and cooling services for over 15 years.
          </p>
          <p style={{ color: '#94A3B8', fontSize: '1.125rem', lineHeight: 1.8 }}>
            Our team consists of background-checked, fully licensed master plumbers and certified HVAC technicians committed to 100% customer satisfaction.
          </p>
        </div>
      </main>
    </>
  )
}
