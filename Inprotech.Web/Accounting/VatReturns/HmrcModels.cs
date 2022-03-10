using System;
using System.Collections.Generic;
using System.Net;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting.VatReturns
{
    public class VatObligations
    {
        public IEnumerable<VatObligation> Obligations { get; set; }
    }

    public class ObligationsResponse
    {
        public HttpStatusCode? Status { get; set; }
        public IEnumerable<VatObligation> Data { get; set; }
    }

    public class VatObligationsQuery
    {
        public int EntityId { get; set; }
        public string TaxNo { get; set; }
        public bool GetOpen { get; set; }
        public bool GetFulfilled { get; set; }
        public DateTime PeriodFrom { get; set; }
        public DateTime PeriodTo { get; set; }
    }

    public class VatDataRetrievalParams
    {
        public int VatBoxNumber { get; set; }
        public int EntityNameNo { get; set; }
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
    }

    public class VatObligation
    {
        public int EntityNameNo { get; set; }
        public string EntityName { get; set; }
        public string EntityTaxCode { get; set; }
        public DateTime Start { get; set; }
        public DateTime End { get; set; }
        public DateTime Due { get; set; }
        public DateTime? Received { get; set; }
        public string Status { get; set; }
        public string PeriodKey { get; set; }
        public bool IsPastDue => Due.Date < DateTime.Now.Date;
        public bool HasLogErrors { get; set; }
    }

    public class AuthToken
    {
        public string RefreshToken { get; set; }

        public string AccessToken { get; set; }
        public int? ExpiresIn { get; set; }
        public string TokenType { get; set; }
    }

    public static class KnownVatDocItems
    {
        public const string Box1 = "VAT Due Sales";
        public const string Box2 = "VAT Due Acquisitions";
        public const string Box4 = "VAT Reclaimed";
        public const string Box6 = "VAT-exclusive Total Sales";
        public const string Box7 = "VAT-exclusive Total Purchases";
        public const string Box8 = "VAT-exclusive Total Supplies";
        public const string Box9 = "VAT-exclusive Total Acquisitions";

        public static string GetValue(int key)
        {
            switch (key)
            {
                case 1:
                    return Box1;
                case 2:
                    return Box2;
                case 4:
                    return Box4;
                case 6:
                    return Box6;
                case 7:
                    return Box7;
                case 8:
                    return Box8;
                case 9:
                    return Box9;
                default:
                    return null;
            }
        }
    }

    public class VatReturnData
    {
        public string PeriodKey { get; set; }
        public decimal VatDueSales { get; set; }
        public decimal VatDueAcquisitions { get; set; }
        public decimal TotalVatDue { get; set; }
        public decimal VatReclaimedCurrPeriod { get; set; }
        public decimal NetVatDue { get; set; }
        public decimal TotalValueSalesExVAT { get; set; }
        public decimal TotalValuePurchasesExVAT { get; set; }
        public decimal TotalValueGoodsSuppliedExVAT { get; set; }
        public decimal TotalAcquisitionsExVAT { get; set; }
        public bool Finalised { get; set; }
    }

    public class VatSubmissionRequest
    {
        public string EntityNo { get; set; }
        public string EntityName { get; set; }
        public string PeriodKey { get; set; }
        public string[] VatValues { get; set; }
        public string AccessToken { get; set; }
        public string VatNo { get; set; }
        public string ToDate { get; set; }
        public string FromDate { get; set; }
        public string selectedEntitiesNames { get; set; }
    }

    public class VatPdfExportRequest
    {
        public string PdfId { get; set; }
        public string EntityName { get; set; }
        public string ToDate { get; set; }
        public string FromDate { get; set; }
    }

    public class VatSuccesResponse
    {
        public DateTime ProcessingDate { get; set; }
        public string PaymentIndicator { get; set; }
        public string FormBundleNumber { get; set; }
        public string ChargeRefNumber { get; set; }
        public bool IsSuccessful { get; set; }
    }

    public class OAuthTokenResponse
    {
        [JsonProperty("token_type")]
        public string TokenType { get; set; }

        [JsonProperty("expires_in")]
        public int ExpiresIn { get; set; }

        [JsonProperty("refresh_token")]
        public string RefreshToken { get; set; }

        [JsonProperty("access_token")]
        public string AccessToken { get; set; }
    }

    public static class KnownHmrcHeaders
    {
        public static readonly string[] FraudPrevention =
        {
            "Gov-Client-Browser-JS-User-Agent",
            "Gov-Client-Connection-Method",
            "Gov-Client-Timezone",
            "Gov-Client-Window-Size",
            "Gov-Vendor-Version",
            "Gov-Client-Multi-Factor",
            "Gov-Client-Public-IP",
            "Gov-Client-User-IDs",
            "Gov-Vendor-Public-IP",
            "Gov-Client-Device-ID",
            "Gov-Client-Public-Port",
            "Gov-Client-Screens",
            "Gov-Vendor-Forwarded",
            "Gov-Client-Local-IPs",
            "Gov-Client-Browser-Plugins",
            "Gov-Client-Browser-Do-Not-Track",
            "Gov-Vendor-License-IDs"
        };
    }
}