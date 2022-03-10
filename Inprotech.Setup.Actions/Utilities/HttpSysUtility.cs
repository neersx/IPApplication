using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class HttpSysUtility
    {
        public static void AddAllReservations(
            IDictionary<string, object> context,
            string path,
            string serviceUser,
            IEventStream eventStream)
        {
            RunForAllBindingUrls(
                                 context,
                                 path,
                                 eventStream,
                                 url =>
                                 {
                                     eventStream.PublishInformation("Adding URL reservation for " + url);
                                     return AddSingleReservation(url, serviceUser);
                                 });
        }

        public static void RemoveAllReservations(
            IEnumerable<string> bindingUrls,
            string path,
            IEventStream eventStream)
        {
            RunForAllBindingUrls(
                                 bindingUrls.Select(a => $"{a}{(path.StartsWith("/") ? string.Empty : "/")}{path}"),
                                 eventStream,
                                 url =>
                                 {
                                     eventStream.PublishInformation("Removing URL reservation for " + url);
                                     return RemoveSingleReservation(url);
                                 });
        }

        static void RunForAllBindingUrls(
            IDictionary<string, object> context,
            string path,
            IEventStream eventStream,
            Func<string, CommandLineUtilityResult> action)
        {
            RunForAllBindingUrls(context.BindingUrls(path), eventStream, action);
        }

        static void RunForAllBindingUrls(
            IEnumerable<string> bindingUrls,
            IEventStream eventStream,
            Func<string, CommandLineUtilityResult> action)
        {
            var errors = new StringBuilder();
            var hasErrors = false;

            foreach (var r in bindingUrls.Select(action))
            {
                if (!String.IsNullOrWhiteSpace(r.Output))
                    eventStream.PublishInformation(r.Output);

                if (r.ExitCode == 0)
                    continue;

                hasErrors = true;
                errors.AppendLine(r.Error);
            }

            if (hasErrors)
                throw new SetupFailedException(errors.ToString());
        }

        public static CommandLineUtilityResult AddSingleReservation(string url, string user)
        {
            RemoveSingleReservation(url);

            return CommandLineUtility.Run(
                                          "netsh",
                                          $"http add urlacl url={url} user=\"{user}\"");
        }

        public static bool IsUrlAclReserved(string url)
        {
            var r = CommandLineUtility.Run("netsh", "http show urlacl");
            return r.ExitCode == 0 && r.Output.Contains(url);
        }

        public static CommandLineUtilityResult RemoveSingleReservation(string url)
        {
            return CommandLineUtility.Run("netsh", $"http delete urlacl url={url}");
        }
    }
}