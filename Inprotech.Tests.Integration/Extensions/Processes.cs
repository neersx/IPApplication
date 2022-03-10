using System;
using System.Diagnostics;
using System.Linq;
using System.Management;

namespace Inprotech.Tests.Integration.Extensions
{
    public static class Processes
    {
        public static bool TryGetFilename(this Process process, out string name)
        {
            try
            {
                string wmiQueryString = $"SELECT ProcessId, ExecutablePath FROM Win32_Process WHERE ProcessId = {process.Id}";
                using (var searcher = new ManagementObjectSearcher(wmiQueryString))
                using (var results = searcher.Get())
                {
                    var mo = results.Cast<ManagementObject>().FirstOrDefault();
                    if (mo != null)
                    {
                        name = (string)mo["ExecutablePath"];
                        return !string.IsNullOrEmpty(name);
                    }
                }

                name = null;
                return false;
            }
            catch
            {
                name = null;
                return false;
            }
        }

        public static void KillProcessAndChildren(this Process process)
        {
            KillProcessAndChildren(process.Id);
        }
        static void KillProcessAndChildren(int pid)
        {
            // Cannot close 'system idle process'.
            if (pid == 0)
            {
                return;
            }
            ManagementObjectSearcher searcher = new ManagementObjectSearcher("Select * From Win32_Process Where ParentProcessID=" + pid);
            ManagementObjectCollection moc = searcher.Get();
            foreach (var o in moc)
            {
                var mo = (ManagementObject)o;
                KillProcessAndChildren(Convert.ToInt32(mo["ProcessID"]));
            }
            try
            {
                Process proc = Process.GetProcessById(pid);
                proc.Kill();
            }
            catch
            {
                // Process already exited.
            }
        }
    }
}