'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth';
import { adminApi, classifyApiError } from '@/lib/api';
import {
  ConversationSessionItem,
  ConversationMessageItem,
  RemoteSuggestion,
} from '@/lib/types';
import {
  Bot,
  X,
  Send,
  RotateCcw,
  Sparkles,
  ThumbsUp,
  ThumbsDown,
  Layers,
  ChevronDown,
  ChevronUp,
  AlertCircle,
  Clock,
  ExternalLink,
  MessageSquare,
  LifeBuoy,
  Minus,
} from 'lucide-react';

export function PixmintChatWidget() {
  const { user, loading } = useAuth();
  const pathname = usePathname();

  const [isOpen, setIsOpen] = useState(false);
  const [session, setSession] = useState<ConversationSessionItem | null>(null);
  const [messages, setMessages] = useState<ConversationMessageItem[]>([]);
  const [suggestions, setSuggestions] = useState<RemoteSuggestion[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandedSources, setExpandedSources] = useState<Record<string, boolean>>({});
  const [feedbackSubmitted, setFeedbackSubmitted] = useState<Record<string, number>>({});
  const [isCollapsed, setIsCollapsed] = useState(false);

  useEffect(() => {
    try {
      const stored = localStorage.getItem('pixmint-widget-collapsed');
      if (stored === 'true') setIsCollapsed(true);
    } catch {}
  }, []);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Listen for custom trigger to open chat from other parts of the admin panel (e.g. /bot dashboard)
  useEffect(() => {
    const handleOpen = () => {
      setIsOpen(true);
    };
    window.addEventListener('open-pixmint-bot', handleOpen);
    return () => window.removeEventListener('open-pixmint-bot', handleOpen);
  }, []);

  // Auto-scroll to bottom of conversation
  useEffect(() => {
    if (isOpen && messages.length > 0) {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [isOpen, messages, isSending]);

  // Focus input when opened
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 150);
    }
  }, [isOpen]);

  // Load session and suggestions on mount or when opened
  const initSession = useCallback(async (forceNew = false): Promise<ConversationSessionItem | null> => {
    if (!user) return null;
    setIsLoading(true);
    setError(null);
    try {
      // 1. Get or reuse active admin session
      const activeSession = await adminApi.getOrCreateBotChatSession({
        newSession: forceNew,
      });
      setSession(activeSession);

      // 2. Fetch existing messages for this session
      if (activeSession?.id) {
        try {
          const history = await adminApi.getBotChatSessionMessages(activeSession.id);
          setMessages(history || []);
        } catch (histErr) {
          console.warn('[PIXMINT_BOT_WIDGET] Could not load message history:', histErr);
          setMessages([]);
        }
      }

      // 3. Load suggestions for admin role
      try {
        const sug = await adminApi.getBotChatSuggestions('admin');
        setSuggestions(sug || []);
      } catch (sugErr) {
        console.warn('[PIXMINT_BOT_WIDGET] Could not load suggestions:', sugErr);
      }

      return activeSession;
    } catch (err: any) {
      console.warn('[PIXMINT_BOT_WIDGET] Failed to initialize session:', err);
      const classified = classifyApiError(err);
      setError(classified.message || err?.message || 'Unable to connect to PIXMINT BOT service.');
      return null;
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  useEffect(() => {
    if (user && isOpen && !session) {
      initSession(false);
    }
  }, [user, isOpen, session, initSession]);

  // STRICT REQUIREMENT: Only visible AFTER login, never before
  if (loading || !user) {
    return null;
  }

  const isAuthPage =
    pathname === '/login' ||
    pathname === '/forgot-password' ||
    pathname === '/verify' ||
    pathname?.startsWith('/registration');
  if (isAuthPage) {
    return null;
  }

  // Do not render floating launcher on /bot or /helpdesk when closed (dedicated management pages)
  const isDedicatedPage = pathname === '/bot' || pathname?.startsWith('/helpdesk');
  if (isDedicatedPage && !isOpen) {
    return null;
  }

  const handleSendMessage = async (textToSend?: string) => {
    const content = (textToSend || inputText).trim();
    if (!content || isSending) return;

    setError(null);

    let activeSession = session;
    if (!activeSession?.id) {
      activeSession = await initSession(false);
    }

    const currentSessionId = activeSession?.id;
    if (!currentSessionId) {
      setError('Chat session is not ready. Please check connection and try again.');
      return;
    }

    // Optimistic user message
    const tempUserMsgId = 'temp-' + Date.now();
    const optimisticUserMsg: ConversationMessageItem = {
      id: tempUserMsgId,
      sessionId: currentSessionId,
      userId: user?.id || 'admin',
      sender: 'user',
      content,
      createdAt: Date.now(),
    };

    setMessages((prev) => [...prev, optimisticUserMsg]);
    setInputText('');
    setIsSending(true);

    try {
      const botResponse = await adminApi.sendBotChatMessage(currentSessionId, content);
      setMessages((prev) => [...prev, botResponse]);
      if (session && (session.title === 'New Conversation' || !session.title)) {
        setSession({ ...session, title: content.slice(0, 30) });
      }
    } catch (err: any) {
      const classified = classifyApiError(err);
      setError(classified.message || err?.message || 'Failed to send message.');
    } finally {
      setIsSending(false);
    }
  };

  const handleSuggestionClick = (prompt: string) => {
    handleSendMessage(prompt);
  };

  const handleFeedback = async (messageId: string, rating: 1 | -1) => {
    if (feedbackSubmitted[messageId]) return;
    setFeedbackSubmitted((prev) => ({ ...prev, [messageId]: rating }));
    try {
      await adminApi.submitBotChatFeedback({ messageId, rating });
    } catch (err) {
      console.warn('[PIXMINT_BOT_WIDGET] Feedback submission failed:', err);
    }
  };

  const toggleSourceExpand = (msgId: string) => {
    setExpandedSources((prev) => ({ ...prev, [msgId]: !prev[msgId] }));
  };

  const handleResetChat = () => {
    setMessages([]);
    initSession(true);
  };

  return (
    <>
      {/* ── Floating Launcher / Unified Studio Hub (bottom-6 right-6) ── */}
      {isCollapsed && !isOpen ? (
        <div className="fixed bottom-6 right-6 z-40 select-none">
          <button
            type="button"
            onClick={() => {
              setIsCollapsed(false);
              try { localStorage.setItem('pixmint-widget-collapsed', 'false'); } catch {}
            }}
            className="h-10 w-10 rounded-full bg-slate-900 border border-slate-700 hover:border-emerald-500 shadow-lg hover:shadow-xl flex items-center justify-center p-1.5 transition-all hover:scale-105 cursor-pointer group"
            title="Expand PIXMINT Studio Assistant"
            aria-label="Expand PIXMINT Studio Assistant"
          >
            <div className="relative h-full w-full flex items-center justify-center">
              <img
                src="/images/pixmint_bot_avatar.png"
                alt="PIXMINT"
                className="h-full w-full object-contain"
                onError={(e) => {
                  (e.target as HTMLElement).style.display = 'none';
                  const fallback = (e.target as HTMLElement).parentElement?.querySelector('.fallback-bot-icon');
                  if (fallback) (fallback as HTMLElement).style.display = 'block';
                }}
              />
              <Bot className="fallback-bot-icon h-4 w-4 text-emerald-300 hidden" />
              <span className="absolute -top-1 -right-1 h-2 w-2 rounded-full bg-emerald-500 ring-1 ring-slate-900" />
            </div>
          </button>
        </div>
      ) : (
        <div className="fixed bottom-6 right-6 z-40 select-none flex items-center">
          <div className="flex items-center bg-slate-900/95 backdrop-blur-md border border-slate-700/80 rounded-full shadow-xl hover:shadow-2xl transition-all p-1">
            {/* Main PIXMINT Bot Trigger */}
            <button
              type="button"
              onClick={() => setIsOpen(!isOpen)}
              aria-label={isOpen ? 'Close PIXMINT Bot' : 'Chat with PIXMINT Bot'}
              className="flex items-center gap-2 pl-1.5 pr-2.5 py-1 text-white hover:text-emerald-300 transition-colors cursor-pointer group"
            >
              <div className="relative flex items-center justify-center">
                <div className="h-7 w-7 rounded-full bg-white/10 flex items-center justify-center p-0.5 border border-white/20 overflow-hidden">
                  <img
                    src="/images/pixmint_bot_avatar.png"
                    alt="PIXMINT Bot"
                    className="h-full w-full object-contain"
                    onError={(e) => {
                      (e.target as HTMLElement).style.display = 'none';
                      const fallback = (e.target as HTMLElement).parentElement?.querySelector('.fallback-bot-icon');
                      if (fallback) (fallback as HTMLElement).style.display = 'block';
                    }}
                  />
                  <Bot className="fallback-bot-icon h-4 w-4 text-emerald-300 hidden" />
                </div>
                <span className="absolute -top-0.5 -right-0.5 h-2 w-2 rounded-full bg-emerald-500 ring-2 ring-slate-900" />
              </div>
              <span className="text-xs font-bold font-heading tracking-wide">
                PIXMINT Bot
              </span>
            </button>

            {/* Inline Support Request Trigger */}
            <button
              type="button"
              onClick={() => {
                if (typeof window !== 'undefined') {
                  window.dispatchEvent(new CustomEvent('open-support-widget'));
                }
              }}
              aria-label="Open Help & Support"
              className="flex items-center gap-1 px-2.5 py-1 text-slate-400 hover:text-blue-300 hover:bg-slate-800 rounded-full text-xs font-mono transition-colors border-l border-slate-700/60 cursor-pointer"
              title="Need Help? Open Support Request"
            >
              <LifeBuoy className="h-3.5 w-3.5 text-blue-400" />
              <span className="text-[11px]">Help</span>
            </button>

            {/* Minimize / Collapse Trigger */}
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                setIsCollapsed(true);
                try { localStorage.setItem('pixmint-widget-collapsed', 'true'); } catch {}
              }}
              aria-label="Minimize Assistant"
              className="p-1 text-slate-500 hover:text-slate-300 hover:bg-slate-800 rounded-full transition-colors cursor-pointer ml-0.5"
              title="Minimize launcher"
            >
              <Minus className="h-3 w-3" />
            </button>
          </div>
        </div>
      )}

      {/* ── Floating Chat Dialog / Sheet ── */}
      {isOpen && (
        <div className="fixed bottom-24 right-6 z-50 w-[420px] max-w-[calc(100vw-32px)] h-[620px] max-h-[calc(100vh-120px)] flex flex-col bg-slate-900/98 backdrop-blur-xl border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-150 text-slate-100 font-sans">
          {/* Header */}
          <div className="px-5 py-3.5 bg-gradient-to-r from-slate-900 via-[#0d1f3d] to-slate-900 border-b border-slate-700/70 flex items-center justify-between shrink-0">
            <div className="flex items-center gap-3">
              <div className="relative">
                <div className="h-9 w-9 rounded-2xl bg-gradient-to-tr from-[#0453cd] to-[#00a877] p-0.5 shadow-md flex items-center justify-center overflow-hidden">
                  <img
                    src="/images/pixmint_bot_mini.png"
                    alt="PIXMINT Mascot"
                    className="h-full w-full object-contain"
                    onError={(e) => {
                      (e.target as HTMLElement).style.display = 'none';
                    }}
                  />
                </div>
                <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full bg-emerald-500 ring-2 ring-slate-900" />
              </div>

              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="text-sm font-bold font-heading text-white">PIXMINT BOT</h3>
                  <span className="px-1.5 py-0.2 rounded-full text-[9px] font-mono font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
                    ONLINE
                  </span>
                </div>
                <p className="text-[10px] text-slate-400 font-mono">
                  Grounded Studio Assistant • Admin Scope
                </p>
              </div>
            </div>

            <div className="flex items-center gap-1 text-slate-400">
              <button
                type="button"
                onClick={() => {
                  setIsOpen(false);
                  if (typeof window !== 'undefined') {
                    window.dispatchEvent(new CustomEvent('open-support-widget'));
                  }
                }}
                title="Need human assistance? Open support ticket"
                aria-label="Need Help?"
                className="flex items-center gap-1 px-2 py-1 rounded-lg text-blue-400 hover:text-blue-200 hover:bg-slate-800 transition-colors text-xs font-mono cursor-pointer mr-1"
              >
                <LifeBuoy className="h-3.5 w-3.5" />
                <span className="text-[11px]">Need Help?</span>
              </button>
              <button
                type="button"
                onClick={handleResetChat}
                title="Start new conversation"
                aria-label="New Conversation"
                className="p-1.5 rounded-lg hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
              >
                <RotateCcw className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => setIsOpen(false)}
                title="Close chat"
                aria-label="Close"
                className="p-1.5 rounded-lg hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Conversation Body */}
          <div className="flex-1 p-4 overflow-y-auto space-y-3.5 text-xs bg-slate-950/60 blueprint-grid">
            {isLoading && messages.length === 0 ? (
              <div className="py-20 text-center space-y-3">
                <div className="flex items-center justify-center gap-2 text-emerald-400">
                  <span className="h-2 w-2 rounded-full bg-emerald-400 animate-bounce" style={{ animationDelay: '0ms' }} />
                  <span className="h-2 w-2 rounded-full bg-emerald-400 animate-bounce" style={{ animationDelay: '150ms' }} />
                  <span className="h-2 w-2 rounded-full bg-emerald-400 animate-bounce" style={{ animationDelay: '300ms' }} />
                </div>
                <p className="text-[11px] text-slate-400 font-mono">Initializing grounded assistant...</p>
              </div>
            ) : messages.length === 0 ? (
              /* Welcome Screen with Mascot & Starter Questions */
              <div className="py-6 px-2 space-y-4 text-center">
                <div className="inline-block relative">
                  <div className="h-16 w-16 mx-auto rounded-3xl bg-gradient-to-tr from-[#0453cd] to-[#00a877] p-1 shadow-lg flex items-center justify-center">
                    <img
                      src="/images/pixmint_bot_waving.png"
                      alt="PIXMINT Bot Waving"
                      className="h-full w-full object-contain"
                    />
                  </div>
                  <span className="absolute -bottom-1 -right-1 px-1.5 py-0.2 rounded-full bg-emerald-950 text-emerald-400 text-[9px] font-mono border border-emerald-700">
                    Active
                  </span>
                </div>

                <div className="space-y-1">
                  <h4 className="text-sm font-bold text-white font-heading">
                    Hello, Studio Admin!
                  </h4>
                  <p className="text-[11px] text-slate-400 max-w-xs mx-auto leading-relaxed">
                    I'm PIXMINT BOT 2.0. Ask me about drawing revisions, CAD standards, curriculum requirements, or studio operations.
                  </p>
                </div>

                {suggestions.length > 0 && (
                  <div className="pt-2 text-left space-y-2">
                    <p className="text-[10px] uppercase font-mono tracking-wider text-slate-400 flex items-center gap-1.5">
                      <Sparkles className="h-3 w-3 text-emerald-400" />
                      Suggested Admin Topics
                    </p>
                    <div className="flex flex-col gap-1.5">
                      {suggestions.slice(0, 4).map((sug) => (
                        <button
                          key={sug.id}
                          type="button"
                          onClick={() => handleSuggestionClick(sug.prompt)}
                          className="w-full text-left p-2.5 rounded-xl bg-slate-800/80 hover:bg-slate-800 hover:border-emerald-500/50 border border-slate-700/70 text-slate-200 hover:text-white transition-all text-xs cursor-pointer flex items-center justify-between group"
                        >
                          <span className="line-clamp-1">{sug.label || sug.prompt}</span>
                          <Send className="h-3 w-3 text-slate-500 group-hover:text-emerald-400 transition-colors shrink-0 ml-2" />
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ) : (
              /* Message Stream */
              messages.map((msg) => {
                const isUser = msg.sender === 'user';
                const hasSources = msg.sources && msg.sources.length > 0;
                const isSourcesOpen = !!expandedSources[msg.id];
                const rating = feedbackSubmitted[msg.id] ?? msg.feedbackRating;

                return (
                  <div
                    key={msg.id}
                    className={`flex flex-col ${isUser ? 'items-end' : 'items-start'} space-y-1`}
                  >
                    <div
                      className={`max-w-[85%] rounded-2xl px-4 py-3 shadow-md ${
                        isUser
                          ? 'bg-[#0453cd] text-white rounded-br-xs'
                          : 'bg-slate-800/90 text-slate-100 border border-slate-700/80 rounded-bl-xs'
                      }`}
                    >
                      {!isUser && (
                        <div className="flex items-center gap-1.5 mb-1.5 pb-1 border-b border-slate-700/50 text-[10px] text-emerald-400 font-mono">
                          <Bot className="h-3 w-3" />
                          <span className="font-semibold">PIXMINT BOT</span>
                          {msg.latencyMs && (
                            <span className="text-slate-400 ml-auto flex items-center gap-0.5">
                              <Clock className="h-2.5 w-2.5" />
                              {msg.latencyMs}ms
                            </span>
                          )}
                        </div>
                      )}

                      <div className="whitespace-pre-wrap leading-relaxed text-xs break-words">
                        {msg.content}
                      </div>

                      {/* Grounded Source Citations */}
                      {hasSources && (
                        <div className="mt-2.5 pt-2 border-t border-slate-700/60">
                          <button
                            type="button"
                            onClick={() => toggleSourceExpand(msg.id)}
                            className="flex items-center gap-1.5 text-[10px] font-mono text-emerald-400 hover:text-emerald-300 cursor-pointer"
                          >
                            <Layers className="h-3 w-3" />
                            <span>
                              {msg.sources!.length} Grounded {msg.sources!.length === 1 ? 'Source' : 'Sources'}
                            </span>
                            {isSourcesOpen ? (
                              <ChevronUp className="h-3 w-3 ml-auto" />
                            ) : (
                              <ChevronDown className="h-3 w-3 ml-auto" />
                            )}
                          </button>

                          {isSourcesOpen && (
                            <div className="mt-2 space-y-1.5 pl-1 border-l-2 border-emerald-500/40">
                              {msg.sources!.map((src, sIdx) => {
                                const title = typeof src === 'string' ? src : src.title || src.path || 'Document';
                                const section = typeof src === 'object' && src.section ? ` § ${src.section}` : '';
                                const category = typeof src === 'object' && src.category ? src.category : '';
                                return (
                                  <div key={sIdx} className="text-[10px] text-slate-300">
                                    <div className="font-semibold text-white flex items-center gap-1">
                                      <span>•</span>
                                      <span>{title}{section}</span>
                                      {category && (
                                        <span className="text-[9px] px-1 rounded-sm bg-slate-700 font-mono text-slate-400 uppercase">
                                          {category}
                                        </span>
                                      )}
                                    </div>
                                  </div>
                                );
                              })}
                            </div>
                          )}
                        </div>
                      )}

                      {/* Feedback buttons on bot messages */}
                      {!isUser && (
                        <div className="mt-2 pt-1.5 flex items-center justify-between text-[10px] text-slate-400 font-mono">
                          <span>Was this helpful?</span>
                          <div className="flex items-center gap-1">
                            <button
                              type="button"
                              onClick={() => handleFeedback(msg.id, 1)}
                              disabled={rating !== undefined}
                              className={`p-1 rounded-md transition-colors cursor-pointer ${
                                rating === 1
                                  ? 'bg-emerald-900/60 text-emerald-300'
                                  : 'hover:bg-slate-700 hover:text-white'
                              }`}
                              title="Helpful"
                            >
                              <ThumbsUp className="h-3 w-3" />
                            </button>
                            <button
                              type="button"
                              onClick={() => handleFeedback(msg.id, -1)}
                              disabled={rating !== undefined}
                              className={`p-1 rounded-md transition-colors cursor-pointer ${
                                rating === -1
                                  ? 'bg-rose-900/60 text-rose-300'
                                  : 'hover:bg-slate-700 hover:text-white'
                              }`}
                              title="Unhelpful"
                            >
                              <ThumbsDown className="h-3 w-3" />
                            </button>
                          </div>
                        </div>
                      )}
                    </div>

                    <span className="text-[9px] font-mono text-slate-500 px-1">
                      {new Date(msg.createdAt).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
                  </div>
                );
              })
            )}

            {/* Thinking / Searching Indicator */}
            {isSending && (
              <div className="flex items-start gap-2">
                <div className="h-7 w-7 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center shrink-0">
                  <Bot className="h-4 w-4 text-emerald-400" />
                </div>
                <div className="bg-slate-800/90 border border-slate-700/80 rounded-2xl rounded-bl-xs px-4 py-2.5 text-xs text-slate-300 flex items-center gap-2">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-bounce" style={{ animationDelay: '0ms' }} />
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-bounce" style={{ animationDelay: '150ms' }} />
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-bounce" style={{ animationDelay: '300ms' }} />
                  <span className="text-[11px] font-mono text-slate-400 ml-1">PIXMINT BOT is thinking...</span>
                </div>
              </div>
            )}

            {/* Error Banner */}
            {error && (
              <div className="p-3 rounded-xl bg-rose-950/70 border border-rose-800 text-rose-200 text-xs flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-rose-400 shrink-0" />
                <span className="flex-1">{error}</span>
                <button
                  type="button"
                  onClick={() => handleSendMessage()}
                  className="px-2 py-0.5 rounded-md bg-rose-900 text-white font-mono text-[10px] hover:bg-rose-800 cursor-pointer"
                >
                  Retry
                </button>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Chat Composer Footer (Explicit High Contrast) */}
          <div className="p-3 bg-slate-900 border-t border-slate-800 shrink-0">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleSendMessage();
              }}
              className="flex items-center gap-2"
            >
              {/* White Background with Crisp Charcoal Text */}
              <div className="flex-1 relative flex items-center bg-white rounded-2xl border border-slate-300 focus-within:ring-2 focus-within:ring-emerald-500 focus-within:border-emerald-500 transition-all shadow-inner">
                <input
                  ref={inputRef}
                  type="text"
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                  placeholder="Ask PIXMINT BOT anything..."
                  disabled={isSending}
                  className="w-full pl-3.5 pr-2 py-2.5 bg-transparent text-[#17212B] placeholder:text-[#8A98A8] text-xs font-medium focus:outline-none rounded-2xl caret-emerald-600 disabled:opacity-60"
                />
              </div>

              {/* Send Button */}
              <button
                type="submit"
                disabled={!inputText.trim() || isSending}
                className="h-10 w-10 rounded-2xl bg-gradient-to-tr from-[#0453cd] to-[#00a877] hover:from-blue-700 hover:to-emerald-600 active:scale-95 text-white flex items-center justify-center shadow-md disabled:opacity-40 disabled:cursor-not-allowed transition-all cursor-pointer shrink-0"
                aria-label="Send message"
              >
                <Send className="h-4 w-4" />
              </button>
            </form>
            <div className="mt-1.5 flex items-center justify-between text-[10px] text-slate-500 font-mono px-1">
              <span>Grounding: D1 + Studio Standards</span>
              <span>Cloudflare AI / Local Grounded</span>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
