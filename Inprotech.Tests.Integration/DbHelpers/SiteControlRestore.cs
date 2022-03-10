using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Integration.DbHelpers
{
    class SiteControlRestore
    {
        static readonly Dictionary<string, object> ValueMap = new()
        {
            {SiteControls.ClientEventText,false},
            {SiteControls.CriticalDates_Internal, "CC"},
            {SiteControls.CriticalDates_External, "CC"},
            {SiteControls.EnableRichTextFormatting, false},
            {SiteControls.KEEPSPECIHISTORY, true},
            {SiteControls.LANGUAGE, null},
            {SiteControls.CURRENCY, "AUD"},
            {SiteControls.HomeNameNo, -283575757},
            {SiteControls.CPA_UseClientCaseCode, false},
            {SiteControls.EnforcePasswordPolicy, false},
            {SiteControls.EntityDefaultsFromCaseOffice, false },
            {SiteControls.RowSecurityUsesCaseOffice, false },
            {SiteControls.ContEntryUnitsAdjmt, false },
            {SiteControls.PrepaymentWarnOver, false},
            {SiteControls.DateStyle, 1},
            {SiteControls.WIPSplitMultiDebtor, false},
            {SiteControls.NarrativeTranslate, false},
            {SiteControls.BillReversalDisabled, 0},
            {SiteControls.BillDateOnlyFromToday, false},
            {SiteControls.BillDateFutureRestriction, 0},
            {SiteControls.InterEntityBilling, 0}
        };

        static readonly Dictionary<string, Type> TypeMap = new()
        {
            {SiteControls.LANGUAGE, typeof(int?)}
        };

        public static void ToDefault(params string[] siteControls)
        {
            var keys = ValueMap.Keys;
            if (siteControls.Any(_ => !keys.Contains(_)))
                throw new Exception("Some of the requested SiteControls have no default value configured here");
            DbSetup.Do(setup =>
            {
                var db = setup.DbContext.Set<SiteControl>().Where(_ => siteControls.Contains(_.ControlId));
                foreach (var siteControl in db)
                {
                    SetValue(siteControl);
                }

                setup.DbContext.SaveChanges();
            });
        }

        static void SetValue(SiteControl siteControl)
        {
            var defaultValue = ValueMap[siteControl.ControlId];
            var type = defaultValue == null ? TypeMap[siteControl.ControlId] : defaultValue.GetType();

            if (type == typeof(string))
            {
                siteControl.StringValue = defaultValue as string;
            }

            else if (type == typeof(int?) || type == typeof(int))
            {
                siteControl.IntegerValue = defaultValue as int?;
            }

            else if (type == typeof(bool?) || type == typeof(bool))
            {
                siteControl.BooleanValue = defaultValue as bool?;
            }

            else if (type == typeof(DateTime) || type == typeof(DateTime?))
            {
                siteControl.DateValue = defaultValue as DateTime?;
            }

            else if (type == typeof(decimal?) || type == typeof(decimal))
            {
                siteControl.DecimalValue = defaultValue as decimal?;
            }
        }
    }
}