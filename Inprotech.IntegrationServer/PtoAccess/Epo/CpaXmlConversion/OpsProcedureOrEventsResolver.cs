using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public interface IOpsProcedureOrEventsResolver
    {
        IEnumerable<OpsProcedureOrEvent> Resolve(registerdocument registerdocument);
    }

    public class OpsProcedureOrEventsResolver : IOpsProcedureOrEventsResolver
    {
        public IEnumerable<OpsProcedureOrEvent> Resolve(registerdocument registerdocument)
        {
            return ExtractProceduralSteps(registerdocument)
                .Union(ExtractDossierEvents(registerdocument))
                .OrderByDescending(e => e.Date);
        }

        static IEnumerable<OpsProcedureOrEvent> ExtractDossierEvents(registerdocument registerdocument)
        {
            if (registerdocument.eventsdata == null)
                yield break;

            foreach (var evt in registerdocument.eventsdata)
            {
                if (!evt.dossierevent.Any()) continue;

                var de = evt.dossierevent.Single();
                
                yield return new OpsProcedureOrEvent
                             {
                                 Date = DateTime.ParseExact(de.eventdate.date.Text.First(), "yyyyMMdd", CultureInfo.InvariantCulture),
                                 FormattedDescription = de.eventtext.First().Text.First(),
                                 Type = de.eventcode.Text.First()
                             };
            }
        }

        static IEnumerable<OpsProcedureOrEvent> ExtractProceduralSteps(registerdocument registerdocument)
        {
            if (registerdocument.proceduraldata == null || !registerdocument.proceduraldata.Any())
                yield break;

            var parser = new ProcedureStepParser();
            
            foreach (var p in registerdocument.proceduraldata.First().proceduralstep)
            {
                var p1 = parser.Parse(p);
                if (p1.DoesNotContainAnyDates) 
                    continue;

                foreach (var d in p1.Date)
                {
                    var formattedDescription =
                        string.Format("{0} ({1})", 
                            string.Join(" ", p1.Description.Values),
                            d.Key.Replace("_", " ").ToLower());

                    var comments = String.Join(";" + Environment.NewLine, ExtractComments(p1));

                    yield return new OpsProcedureOrEvent
                                 {
                                     Type = p1.Code,
                                     FormattedDescription = formattedDescription,
                                     Comments = comments,
                                     Date = d.Value
                                 };
                }
            }
        }

        static IEnumerable<string> ExtractComments(ProcedureStepParser.ParsedProceduralStep p1)
        {
            string stepName;
            if (p1.Text.TryGetValue("STEP_DESCRIPTION_NAME", out stepName) && !string.IsNullOrWhiteSpace(stepName))
                yield return stepName;

            foreach (var additional in p1.Text.Where(k => k.Key != "STEP_DESCRIPTION_NAME"))
                yield return string.Format("{0}: {1}", additional.Key.Replace('_', ' '), additional.Value);

            if (!string.IsNullOrWhiteSpace(p1.Timelimit))
                yield return "Time Limit: " + p1.Timelimit;
        }
    }

    public class OpsProcedureOrEvent
    {
        public string Type { get; set; }

        public DateTime Date { get; set; }

        public string FormattedDescription { get; set; }

        public string Comments { get; set; }
    }

}