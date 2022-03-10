namespace Inprotech.Infrastructure.Security
{
    public enum ApplicationSubject
    {
        /// <summary>Required for business entities that are yet to define task security</summary>
        NotDefined = -1,

        ///<summary>Information regarding the charges that would apply for various types of fees; e.g. renewals, filing.</summary>
        FeesandChargesCalculations = 1,

        ///<summary>Physical files that are attached by references to cases and names.</summary>
        Attachments = 2,

        ///<summary>The estimates that have been provided for charges that would apply for various types of fees; e.g. renewals, filing.</summary>
        FeesandChargesEstimates = 3,

        ///<summary>A break down of fees and charges calculations by Work in Progress Category. Note: this subject is only relevant if the user also has access to Fees and Charges Calculations.</summary>
        FeesandChargesbyWipCategory = 4,

        ///<summary>A break down of fees and charges calculations by Work in Progress Category then by Rate Calculation. 
        /// Note: this subject is only relevant if the user also has access to Fees and Charges Calculations and Fees and Charges by WIP Category.</summary>
        FeesandChargesbyRateCalculation = 5,

        /// <summary>Sensitive elements of the fees and charges calculation performed such as exchange rates, equivalent local currency values, original currency values and margins included. </summary>
        FeesandChargesElements = 6,

        /// <summary>Information regarding renewals.</summary>
        Renewals = 7,

        /// <summary>
        /// Information regarding the history and progress of e-filing transactions, including package status and contents
        /// </summary>
        EFiling = 8,

        /// <summary>Note: this subject is only relevant if the user also has access to Fees an Information regarding how a case/name is to be billed.</summary>
        BillingInstructions = 100,

        ///<summary>A record of past billing including billing totals and access to past bills.</summary>
        BillingHistory = 101,

        ///<summary>Work In Progress information including lists of items, their details and outstanding balances.</summary>
        WorkInProgressItems = 120,

        ///<summary>Accounts receivable information including lists of items, their details and outstanding balances.  See separate topic to include Prepayments.</summary>
        ReceivableItems = 200,

        ///<summary>Information regarding money paid by a debtor in advance of the work being performed.</summary>
        Prepayments = 201,

        ///<summary>Information regarding money paid by a debtor in a trust account.</summary>
        TrustAccounting = 202,

        ///<summary>Accounts payable information including lists of items, their details and outstanding balances.</summary>
        PayableItems = 300,

        ///<summary>Information regarding Suppliers including purchasing deafaults, payment arrangements and instructions.</summary>
        SupplierDetails = 301,

        ///<summary>Contact management and other marketing activities.</summary>
        ContactActivities = 400,

        ///<summary>Information regarding the value of a name to your firm from a sales perspective.</summary>
        SalesHighlights = 401,

        ///<summary>When viewing an individual, this subject provides additional background information about the individual's employer.</summary>
        EmployerInformation = 402
    }
}
