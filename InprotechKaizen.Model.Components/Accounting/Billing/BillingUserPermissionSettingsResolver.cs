using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Security;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IBillingUserPermissionSettingsResolver
    {
        Task<BillingUserPermissionsSettings> Resolve();
    }

    public class BillingUserPermissionSettingsResolver : IBillingUserPermissionSettingsResolver
    {
        readonly ISiteControlReader _siteControlReader;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IFunctionSecurityProvider _functionSecurityProvider;
        readonly ISecurityContext _securityContext;

        public BillingUserPermissionSettingsResolver(ISiteControlReader siteControlReader, 
                                                     ITaskSecurityProvider taskSecurityProvider, 
                                                     IFunctionSecurityProvider functionSecurityProvider, 
                                                     ISecurityContext securityContext)
        {
            _siteControlReader = siteControlReader;
            _taskSecurityProvider = taskSecurityProvider;
            _functionSecurityProvider = functionSecurityProvider;
            _securityContext = securityContext;
        }
        
        public async Task<BillingUserPermissionsSettings> Resolve()
        {
            var userSettings = new BillingUserPermissionsSettings {CanReverseBill = GetSiteBillReversalSettings()};
            var fs = await _functionSecurityProvider.BestFit(BusinessFunction.Billing, _securityContext.User, _securityContext.User.NameId);
            if (fs != null)
            {
                userSettings.CanCreditBill = fs.CanCredit && _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create);
                userSettings.CanFinaliseBill = fs.CanFinalise;
                if (!fs.CanReverse)
                {
                    userSettings.CanReverseBill = BillReversalTypeAllowed.ReversalNotAllowed;
                }
            }

            userSettings.CanDeleteCreditNote = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Delete);
            userSettings.CanDeleteDebitNote = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Delete);

            userSettings.CanMaintainCreditNote = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Modify);
            userSettings.CanMaintainDebitNote = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Modify);

            userSettings.CanAdjustForeignBillValue = _taskSecurityProvider.HasAccessTo(ApplicationTask.AdjustForeignBillValue);
            userSettings.CanAdjustForeignBillLineValues = _taskSecurityProvider.HasAccessTo(ApplicationTask.AdjustForeignBillLineValues);

            userSettings.WriteDownLimit = _securityContext.User.WriteDownLimit;
            
            return userSettings;
        }

        BillReversalTypeAllowed GetSiteBillReversalSettings()
        {
            var siteSetting = BillReversalTypeAllowed.ReversalAllowed;

            var billReversalSetting = _siteControlReader.Read<int?>(SiteControls.BillReversalDisabled);
            if (billReversalSetting != null) 
            {
                switch (billReversalSetting)
                {
                    case (int)BillReversalTypeAllowed.ReversalAllowed: siteSetting = BillReversalTypeAllowed.ReversalAllowed; break;
                    case (int)BillReversalTypeAllowed.ReversalNotAllowed: siteSetting = BillReversalTypeAllowed.ReversalNotAllowed; break;
                    case (int)BillReversalTypeAllowed.CurrentPeriodReversalAllowed: siteSetting = BillReversalTypeAllowed.CurrentPeriodReversalAllowed; break;
                }
            }

            return siteSetting;
        }
    }

    public class BillingUserPermissionsSettings
    {
        public BillReversalTypeAllowed CanReverseBill { get; set; }

        public bool CanFinaliseBill { get; set; }

        public bool CanCreditBill { get; set; }
    
        public bool CanDeleteDebitNote { get; set; }
        
        public bool CanDeleteCreditNote { get; set; }

        public bool CanAdjustForeignBillValue { get; set; }

        public bool CanAdjustForeignBillLineValues { get; set; }
        
        public decimal? WriteDownLimit { get; set; }
        public bool CanMaintainCreditNote { get; set; }
        public bool CanMaintainDebitNote { get; set; }
    }
}