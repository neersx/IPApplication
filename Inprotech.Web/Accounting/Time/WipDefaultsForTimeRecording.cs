using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace Inprotech.Web.Accounting.Time
{
    public static class WipDefaultsForTimeRecording
    {
        public static WipTemplateFilterCriteria ForTimesheet(this WipTemplateFilterCriteria filterCriteria, int? caseKey)
        {
            var f = filterCriteria ?? new WipTemplateFilterCriteria();

            f.WipCategory.IsServices = true;
            f.UsedByApplication.IsTimesheet = true;
            f.ContextCriteria.CaseKey = caseKey;

            return f;
        }
    }
}
