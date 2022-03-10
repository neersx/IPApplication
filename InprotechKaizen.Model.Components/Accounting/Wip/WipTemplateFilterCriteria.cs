using System;
using System.Collections.Generic;
using System.Xml.Linq;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipTemplateFilterCriteria
    {
        public class WipCategoryFilter
        {
            public bool? IsServices { get; set; }

            public bool? IsDisbursements { get; set; }

            public bool? IsOverheads { get; set; }
        }

        public class UsedByApplicationFilter
        {
            public bool? IsTimesheet { get; set; }

            public bool? IsWip { get; set; }
            
            public bool? IsBilling { get; set; }
        }

        public class ContextCriteriaFilter
        {
            public int? CaseKey { get; set; }
        }

        public WipCategoryFilter WipCategory { get; set; } = new ();

        public UsedByApplicationFilter UsedByApplication { get; set; } = new ();

        public ContextCriteriaFilter ContextCriteria { get; set; } = new ();
    }

    public static class WipTemplateFilterCriteriaBuilder
    {
        public static bool IsEmpty(this WipTemplateFilterCriteria.WipCategoryFilter filter)
        {
            if (filter == null) return true;
            return filter.IsOverheads == null && filter.IsServices == null && filter.IsDisbursements == null;
        }

        public static bool IsEmpty(this WipTemplateFilterCriteria.UsedByApplicationFilter filter)
        {
            if (filter == null) return true;
            return filter.IsTimesheet == null && filter.IsWip == null && filter.IsBilling == null;
        }
        
        public static bool IsEmpty(this WipTemplateFilterCriteria.ContextCriteriaFilter filter)
        {
            if (filter == null) return true;
            return filter.CaseKey == null;
        }

        public static XElement Build(this WipTemplateFilterCriteria filterCriteria)
        {
            if (filterCriteria == null) throw new ArgumentNullException(nameof(filterCriteria));

            return new XElement("wp_ListWipTemplate",
                                new XElement("FilterCriteria", BuildFilterCriteria(filterCriteria.WipCategory, filterCriteria.UsedByApplication)),
                                new XElement("ContextCriteria", BuildContextCriteria(filterCriteria.ContextCriteria)));
        }

        static IEnumerable<XElement> BuildContextCriteria(WipTemplateFilterCriteria.ContextCriteriaFilter contextCriteriaFilter)
        {
            if (contextCriteriaFilter.IsEmpty()) yield break;
            
            yield return new XElement("CaseKey", contextCriteriaFilter.CaseKey);
        }

        static IEnumerable<XElement> BuildFilterCriteria(WipTemplateFilterCriteria.WipCategoryFilter wipCategoryFilter, WipTemplateFilterCriteria.UsedByApplicationFilter usedByApplicationFilter)
        {
            if (BuildWipCategoryFilterCriteria(wipCategoryFilter, out var wipCategory))
                yield return wipCategory;

            if (BuildUsedByApplicationFilterCriteria(usedByApplicationFilter, out var usedByApplication))
                yield return usedByApplication;
        }

        static bool BuildWipCategoryFilterCriteria(WipTemplateFilterCriteria.WipCategoryFilter wipCategoryFilter, out XElement wipCategory)
        {
            wipCategory = null;

            if (wipCategoryFilter.IsEmpty()) return false;
            
            wipCategory = new XElement("WipCategory");

            if (wipCategoryFilter.IsDisbursements != null)
                wipCategory.Add(new XElement("IsDisbursements", Convert.ToInt32((bool) wipCategoryFilter.IsDisbursements)));

            if (wipCategoryFilter.IsServices != null)
                wipCategory.Add(new XElement("IsServices", Convert.ToInt32((bool) wipCategoryFilter.IsServices)));

            if (wipCategoryFilter.IsOverheads != null)
                wipCategory.Add(new XElement("IsOverheads", Convert.ToInt32((bool) wipCategoryFilter.IsOverheads)));
            
            return true;
        }

        static bool BuildUsedByApplicationFilterCriteria(WipTemplateFilterCriteria.UsedByApplicationFilter usedByApplicationFilter, out XElement usedByApplication)
        {
            usedByApplication = null;

            if (usedByApplicationFilter.IsEmpty()) return false;
            
            usedByApplication = new XElement("UsedByApplication");

            if (usedByApplicationFilter.IsBilling != null)
                usedByApplication.Add(new XElement("IsBilling", Convert.ToInt32((bool) usedByApplicationFilter.IsBilling)));
            
            if (usedByApplicationFilter.IsWip != null)
                usedByApplication.Add(new XElement("IsWip", Convert.ToInt32((bool) usedByApplicationFilter.IsWip)));

            if (usedByApplicationFilter.IsTimesheet != null)
                usedByApplication.Add(new XElement("IsTimesheet", Convert.ToInt32((bool) usedByApplicationFilter.IsTimesheet)));
            
            return true;
        }
    }
}