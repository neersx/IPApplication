using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;

namespace Inprotech.Infrastructure.Notifications.Validation
{
    public interface IApplicationAlerts
    {
        bool TryParse(string xmlString, out IEnumerable<ApplicationAlert> alerts);
    }

    public enum AlertSeverity
    {
        Information, Warning, UserError, ProcessingError, SystemError
    }

    public class ApplicationAlerts : IApplicationAlerts
    {
        public bool TryParse(string xmlString, out IEnumerable<ApplicationAlert> alerts)
        {
            if (string.IsNullOrWhiteSpace(xmlString) || !xmlString.Contains("<Alert>"))
            {
                alerts = Enumerable.Empty<ApplicationAlert>();
                return false;
            }

            alerts = Parse(xmlString).ToArray();
            return true;
        }

        static IEnumerable<ApplicationAlert> Parse(string xmlString)
        {
            var workXml = "<root>" + xmlString + "</root>";
            var xdResult = XDocument.Parse(workXml);

            foreach (var alertElement in xdResult.Descendants("Alert"))
            {
                var alertObj = new ApplicationAlert
                               {
                                   AlertID = (string) alertElement.Element("AlertID"),
                                   Message = (string) alertElement.Element("Message"),
                                   DefaultMessage = (string) alertElement.Element("Message")
                               };

                if (alertElement.Descendants("Substitute").Any())
                {
                    alertObj.ContextArguments = (from s in alertElement.Descendants("Substitute")
                                                 select s.Value).ToList();
                }

                if (alertObj.ContextArguments.Any())
                {
                    if (alertObj.Message.Split('{').Count() - 1 == alertObj.ContextArguments.Count())
                    {
                        alertObj.Message = string.Format(alertObj.Message, alertObj.ContextArguments.Cast<object>().ToArray());
                    }
                }

                yield return alertObj;
            }
        }
    }

    public class ApplicationAlert
    {
        public ApplicationAlert()
        {
            ContextArguments = new List<string>();
        }

        public string AlertID { get; set; }
        public string DefaultMessage { get; set; }
        public string Message { get; set; }
        public AlertSeverity Severity { get; set; }
        public IEnumerable<string> ContextArguments { get; set; }
    }

    public static class ApplicationAlertExtensions
    {
        public static string Flatten(this IEnumerable<ApplicationAlert> alerts)
        {
            return (alerts ?? Enumerable.Empty<ApplicationAlert>()).Any()
                ? string.Join(Environment.NewLine, alerts.Select(_ => _.Message ?? _.DefaultMessage))
                : null;
        }
    }
}