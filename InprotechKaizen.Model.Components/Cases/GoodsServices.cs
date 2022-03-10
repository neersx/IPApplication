using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IGoodsServices
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        bool DoesClassExists(Case @case, string classId);

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        string AddClass(Case @case, string classId);

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        void AddOrUpdate(Case @case, string classId, string caseText = null, int? languageCode = null, DateTime? firstUseDate = null, DateTime? firstUseInCommerce = null);
    }

    public class GoodsServices : IGoodsServices
    {
        readonly IClasses _classes;
        readonly ISiteConfiguration _siteConfiguration;
        readonly Func<DateTime> _systemClock;

        public GoodsServices(IClasses classes, ISiteConfiguration siteConfiguration, Func<DateTime> systemClock)
        {
            if (classes == null) throw new ArgumentNullException("classes");
            if (siteConfiguration == null) throw new ArgumentNullException("siteConfiguration");
            if (systemClock == null) throw new ArgumentNullException("systemClock");

            _classes = classes;
            _siteConfiguration = siteConfiguration;
            _systemClock = systemClock;
        }

        public string AddClass(Case @case, string classId)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var localClassesList = GetExistingLocalClasses(@case).ToList();

            var tmClass = _classes.GetLocalClass(@case.PropertyType.Code, @case.Country.Id, classId);
            if (localClassesList.Contains(tmClass.Class))
            {
                return tmClass.Class;
            }

            localClassesList.Add(tmClass.Class);
            @case.LocalClasses = string.Join(",", localClassesList.OrderBy(_ => _));

            var intlClassesList = GetExistingIntlClasses(@case).ToList();
            if (!intlClassesList.Contains(tmClass.IntClass))
            {
                intlClassesList.Add(tmClass.IntClass);
                @case.IntClasses = string.Join(",", intlClassesList.OrderBy(_ => _));
            }

            return tmClass.Class;
        }

        public bool DoesClassExists(Case @case, string classId)
        {
            var existingLocalClasses = GetExistingLocalClasses(@case).ToList();
            return existingLocalClasses.Any() && existingLocalClasses.Contains(classId);
        }

        // Fragile code
        //Ensure Localclass is added in case and saved before adding casetext 
        //This is to take care of the casetexts records manipulated by triggers - Cases-tI_CASES_Classes, CaseText-tI_CASETEXT_Classes
        public void AddOrUpdate(Case @case, string classId, string caseText = null, int? languageCode = null, DateTime? firstUseDate = null, DateTime? firstUseInCommerce = null)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            //Do not change this step!
            if (!DoesClassExists(@case, classId))
            {
                throw new Exception("Local class does not exists for the case. Class - " + classId);
            }

            if (caseText != null)
            {

                // This logic is not appropriate for FILE integration because this logic here only writes to neutral language text
                // for FILE, there is elaborate precedence to derive goods and services text.
                var inprotechGoodsService = @case.GoodsAndServices()
                                                 .Where(_ => _.Class == classId && _.Language == languageCode)
                                                 .OrderByDescending(_ => _.Number)
                                                 .FirstOrDefault();

                var specHistory = _siteConfiguration.KeepSpecificationHistory;

                if (inprotechGoodsService != null && (!specHistory || string.IsNullOrWhiteSpace(inprotechGoodsService.Text)))
                {
                    inprotechGoodsService.Text = caseText;
                }
                else
                {
                    var textNo = (@case.GoodsAndServices().Max(_ => _.Number) ?? -1) + 1;
                    AddClassText(@case, classId, caseText, textNo, languageCode);
                }
            }

            AddOrUpdateFirstUseSet(@case, classId, firstUseDate, firstUseInCommerce);
        }

        void AddClassText(Case @case, string classId, string text, int textNo, int? language)
        {
            @case.CaseTexts.Add(new CaseText(@case.Id, KnownTextTypes.GoodsServices, (short?) textNo, classId)
            {
                Text = text,
                ModifiedDate = _systemClock(),
                Language = language
            });
        }

        static void AddOrUpdateFirstUseSet(Case @case, string classId, DateTime? firstUse, DateTime? firstUseInCommerce)
        {
            if (firstUse == null && firstUseInCommerce == null)
            {
                return;
            }

            var classFirstUse = @case.ClassFirstUses.FirstOrDefault(_ => _.Class == classId);

            if (classFirstUse == null)
            {
                classFirstUse = new ClassFirstUse(@case.Id, classId);
                @case.ClassFirstUses.Add(classFirstUse);
            }

            if (firstUse != null)
            {
                classFirstUse.FirstUsedDate = firstUse;
            }

            if (firstUseInCommerce != null)
            {
                classFirstUse.FirstUsedInCommerceDate = firstUseInCommerce;
            }
        }

        static IEnumerable<string> GetExistingLocalClasses(Case @case)
        {
            return string.IsNullOrWhiteSpace(@case.LocalClasses)
                ? Enumerable.Empty<string>()
                : @case.LocalClasses.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries);
        }

        static IEnumerable<string> GetExistingIntlClasses(Case @case)
        {
            return string.IsNullOrWhiteSpace(@case.IntClasses)
                ? Enumerable.Empty<string>()
                : @case.IntClasses.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries);
        }
    }
}