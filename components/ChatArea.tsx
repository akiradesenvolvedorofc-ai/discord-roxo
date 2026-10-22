"use client";
import { Hash, Users } from "lucide-react";
import MessageList from "@/components/MessageList";
import MessageInput from "@/components/MessageInput";
import { useChannelMessages } from "@/hooks/useChannelMessages";
import { useTyping } from "@/hooks/useTyping";
export default function ChatArea({channelId,channelName,profile}:{channelId:string,channelName:string,profile:any}){const {messages,sendMessage,loading}=useChannelMessages(channelId);const {typingUsers,sendTyping}=useTyping(channelId,profile?.username??"alguém");return <main className="flex min-w-0 flex-1 flex-col bg-surface-600/70"><header className="flex h-[68px] shrink-0 items-center justify-between border-b border-white/[.06] px-5 shadow-sm shadow-black/10"><div className="flex min-w-0 items-center gap-3"><Hash size={20} className="shrink-0 text-white/40"/><div className="min-w-0"><h1 className="truncate font-bold">{channelName}</h1><p className="text-[11px] text-white/35">Um bom lugar para começar uma conversa.</p></div></div><div className="flex items-center gap-2 rounded-xl border border-white/[.06] bg-white/[.03] px-3 py-2 text-xs text-white/45"><Users size={15}/> Comunidade</div></header><MessageList messages={messages} loading={loading} typingUsers={typingUsers} currentUserId={profile?.id}/><MessageInput onSend={sendMessage} onTyping={sendTyping} channelName={channelName}/></main>}
