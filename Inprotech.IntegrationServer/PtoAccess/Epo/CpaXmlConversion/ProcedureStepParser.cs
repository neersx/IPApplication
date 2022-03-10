using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class ProcedureStepParser
    {
        public ParsedProceduralStep Parse(proceduralstep proceduralstep)
        {
            return new ParsedProceduralStep
                   {
                       Code = ExtractCode(proceduralstep),
                       Description = ExtractStepDescription(proceduralstep),
                       Text = ExtractStepTexts(proceduralstep),
                       Date = ExtractStepDates(proceduralstep),
                       Timelimit = ExtrcatTimeLimit(proceduralstep)
                   };
        }

        static string ExtrcatTimeLimit(proceduralstep proceduralstep)
        {
            var timeLimit = proceduralstep.timelimit;
            return proceduralstep.timelimit == null ? null : (timeLimit.Text.First() + " " + timeLimit.timelimitunit);
        }

        static Dictionary<string, DateTime> ExtractStepDates(proceduralstep proceduralstep)
        {
            if (proceduralstep.proceduralstepdate == null)
                return new Dictionary<string, DateTime>();

            return proceduralstep
                .proceduralstepdate
                .ToDictionary(
                    k => k.stepdatetype,
                    v => DateTime.ParseExact(v.date.Text.First(), "yyyyMMdd", CultureInfo.InvariantCulture)
                );
        }

        static Dictionary<string, string> ExtractStepDescription(proceduralstep proceduralstep)
        {
            if (proceduralstep.proceduralsteptext == null)
                return new Dictionary<string, string>();

            return proceduralstep.proceduralsteptext
                .Where(k => k.steptexttype == "STEP_DESCRIPTION")
                .ToDictionary(
                    k => k.steptexttype,
                    v => v.Text.First()
                );
        }

        static Dictionary<string, string> ExtractStepTexts(proceduralstep proceduralstep)
        {
            if (proceduralstep.proceduralsteptext == null)
                return new Dictionary<string, string>();

            return proceduralstep.proceduralsteptext
                .Where(k => k.steptexttype != "STEP_DESCRIPTION" && k.Text != null)
                .ToDictionary(
                    k => k.steptexttype,
                    v => v.Text.First()
                );
        }

        static string ExtractCode(proceduralstep proceduralstep)
        {
            return proceduralstep.proceduralstepcode?.Text.First();
        }

        public class ParsedProceduralStep
        {
            public string Code { get; set; }

            public Dictionary<string, string> Description { get; set; }

            public Dictionary<string, string> Text { get; set; }

            public Dictionary<string, DateTime> Date { get; set; }

            public string Timelimit { get; set; }

            public bool DoesNotContainAnyDates => Date.Keys.Count == 0;
        }
    }
}