import React, { useState } from 'react'
import Head from 'next/head'
import Link from 'next/link'

export default function Contact() {
  const [submitted, setSubmitted] = useState(false)
  return (
    <>
      <Head><title>Contact Us | Acme Home Services</title></Head>
      <header style={{ background: '#0F172A', borderBottom: '1px solid #1E293B', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#fff' }}>
        <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#38BDF8' }}>🛠️ Acme Home Services</div>
        <nav style={{ display: 'flex', gap: '1.5rem', fontSize: '0.9375rem', fontWeight: 600 }}>
          <Link href="/" style={{ color: '#94A3B8', textDecoration: 'none' }}>Home</Link>
          <Link href="/services" style={{ color: '#94A3B8', textDecoration: 'none' }}>Services</Link>
          <Link href="/about" style={{ color: '#94A3B8', textDecoration: 'none' }}>About</Link>
          <Link href="/pricing" style={{ color: '#94A3B8', textDecoration: 'none' }}>Pricing</Link>
          <Link href="/contact" style={{ color: '#38BDF8', textDecoration: 'none' }}>Contact</Link>
        </nav>
      </header>
      <main style={{ fontFamily: 'system-ui, sans-serif', background: '#020617', color: '#F8FAFC', minHeight: '80vh', padding: '4rem 2rem' }}>
        <div style={{ maxWidth: '600px', margin: '0 auto', background: '#0F172A', border: '1px solid #1E293B', borderRadius: '16px', padding: '2.5rem' }}>
          <h1 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '0.5rem', color: '#38BDF8' }}>Contact & Appointment Request</h1>
          <p style={{ color: '#94A3B8', fontSize: '0.9375rem', marginBottom: '2rem' }}>Fill out the form below or call us directly at (312) 555-0199.</p>

          {submitted ? (
            <div style={{ background: 'rgba(56,189,248,0.12)', border: '1px solid #38BDF8', padding: '1.5rem', borderRadius: '8px', color: '#38BDF8', fontWeight: 700, textAlign: 'center' }}>
              ✅ Thank you! Our team will contact you within 15 minutes.
            </div>
          ) : (
            <form onSubmit={(e) => { e.preventDefault(); setSubmitted(true); }} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <input type="text" placeholder="Your Name" required style={{ padding: '0.75rem', background: '#020617', border: '1px solid #1E293B', borderRadius: '6px', color: '#fff' }} />
              <input type="email" placeholder="Email Address" required style={{ padding: '0.75rem', background: '#020617', border: '1px solid #1E293B', borderRadius: '6px', color: '#fff' }} />
              <input type="tel" placeholder="Phone Number" required style={{ padding: '0.75rem', background: '#020617', border: '1px solid #1E293B', borderRadius: '6px', color: '#fff' }} />
              <textarea placeholder="Describe your plumbing/HVAC issue..." rows={4} style={{ padding: '0.75rem', background: '#020617', border: '1px solid #1E293B', borderRadius: '6px', color: '#fff' }} />
              <button type="submit" style={{ background: '#38BDF8', color: '#0F172A', fontWeight: 800, padding: '0.875rem', borderRadius: '6px', border: 'none', cursor: 'pointer', fontSize: '1rem' }}>Submit Request →</button>
            </form>
          )}
        </div>
      </main>
    </>
  )
}
