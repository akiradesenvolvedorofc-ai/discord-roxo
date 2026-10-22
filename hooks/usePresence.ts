"use client";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
export type OnlineUser={user_id:string,username:string};
export function usePresence(userId:string,username:string){const [onlineUsers,setOnlineUsers]=useState<OnlineUser[]>([]);useEffect(()=>{if(!userId)return;const sb=createClient();const channel=sb.channel("online-users",{config:{presence:{key:userId}}}).on("presence",{event:"sync"},()=>{const state=channel.presenceState<OnlineUser>();const users=Object.values(state).flat().filter((u:any)=>u.user_id&&u.username) as OnlineUser[];setOnlineUsers(Array.from(new Map(users.map(u=>[u.user_id,u])).values()))}).subscribe(async status=>{if(status==="SUBSCRIBED")await channel.track({user_id:userId,username});});return()=>{void sb.removeChannel(channel)}},[userId,username]);return {onlineUsers};}
