public with sharing class ArcadiaApiWrapper {
    
    public class PropertyInput {
        @AuraEnabled public String scenarios {get; set;}
        @AuraEnabled public String keyName {get; set;}
        @AuraEnabled public String dataType {get; set;}
        @AuraEnabled public String dataValue {get; set;}
        @AuraEnabled public String operator {get; set;}
        @AuraEnabled public String unit {get; set;}
        @AuraEnabled public String accuracy {get; set;}
    }
    
    // getUtilities
    
    /* public class GetUtilitiesResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public Integer count {get; set;}
        @AuraEnabled public List<GetUtilitiesResult> results {get; set;}
        @AuraEnabled public Integer pageCount {get; set;}
        @AuraEnabled public Integer pageStart {get; set;}
    }
    
    public class GetUtilitiesResult {
        @AuraEnabled public String lseId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String lseCode {get; set;}
        @AuraEnabled public String code {get; set;}
    } */
    
    // createAccount
    
    public class CreateAccountRequest {
        @AuraEnabled public String providerAccountId {get; set;}
        @AuraEnabled public String accountName {get; set;}
        @AuraEnabled public Address address {get; set;}
        @AuraEnabled public CreateAccountProperty properties {get; set;}
    }
    
    public class Address {
        @AuraEnabled public String addressString {get; set;}
    }
    
    public class CreateAccountProperty {
        @AuraEnabled public PropertyInput customerClass {get; set;}
    }
    
    public class CreateAccountResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<CreateAccountResult> results {get; set;}
    }
    
    public class CreateAccountResult {
        @AuraEnabled public CreateAccountResultProperty properties {get; set;}
        @AuraEnabled public String accountId {get; set;}
        @AuraEnabled public List<Tariff> tariffs {get; set;}
    }  
    
    public class CreateAccountResultProperty {
        @AuraEnabled public PropertyInput lseId {get; set;}
        @AuraEnabled public PropertyInput territoryId {get; set;}
    }   
    
    public class Tariff {
        @AuraEnabled public String masterTariffId {get; set;}
        @AuraEnabled public String tariffCode {get; set;}
        @AuraEnabled public String tariffName {get; set;}
        @AuraEnabled public String billingPeriod {get; set;}
        
    }  
    
    // setProperties
    
    public class SetPropertyRequest {
        @AuraEnabled public String keyName {get; set;}
        @AuraEnabled public String dataValue {get; set;}
        @AuraEnabled public Decimal accuracy {get; set;}
    }
    
    public class SetPropertyResponse {
        @AuraEnabled public String status {get; set;}
    }
    
    // calculateKwh
    
    public class CalculateKwhRequest {
        @AuraEnabled public String fromDateTime {get; set;}
        @AuraEnabled public String toDateTime {get; set;}
        @AuraEnabled public Boolean billingPeriod {get; set;}
        @AuraEnabled public String groupBy {get; set;}
        @AuraEnabled public String detailLevel {get; set;}
        @AuraEnabled public List<PropertyInput> propertyInputs {get; set;}
    }
    
    public class CalculateKwhResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<CalculateKwhResult> results {get; set;}
    }
    
    public class CalculateKwhResult {
        @AuraEnabled public CalculateKwhResultSummary summary {get; set;}
        @AuraEnabled public List<CalculateKwhItem> items {get; set;}
    }
    
    public class CalculateKwhResultSummary {
        @AuraEnabled public Decimal kWh {get; set;}
        @AuraEnabled public Decimal totalCost {get; set;}
    }
    
    public class CalculateKwhItem {
        @AuraEnabled public String rateGroupName {get; set;}
        @AuraEnabled public Decimal itemQuantity {get; set;}
        @AuraEnabled public Decimal cost {get; set;}
        @AuraEnabled public DateTime fromDateTime {get; set;}
        @AuraEnabled public DateTime toDateTime {get; set;}
        @AuraEnabled public String chargeType {get; set;}
    }
    
    // createElectricityProfile
    
    public class CreateElectricityProfileRequest {
        @AuraEnabled public String providerAccountId {get; set;}
        @AuraEnabled public String providerProfileId {get; set;}
        @AuraEnabled public String profileName {get; set;}
        @AuraEnabled public Boolean isDefault {get; set;}
        @AuraEnabled public String serviceTypes {get; set;}
        @AuraEnabled public String sourceId {get; set;}
        @AuraEnabled public CreateElectricityProfileProperty properties {get; set;}
        @AuraEnabled public List<ReadingData> readingData {get; set;}
    }
    
    public class CreateElectricityProfileProperty {
        @AuraEnabled public PropertyInput baselineType {get; set;}
    }
    
    public class ReadingData {
        @AuraEnabled public String fromDateTime {get; set;}
        @AuraEnabled public String toDateTime {get; set;}
        @AuraEnabled public String quantityUnit {get; set;}
        @AuraEnabled public String quantityValue {get; set;}
    }
    
    public class CreateElectricityProfileResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<CreateElectricityProfileResult> results {get; set;}
    }
    
    public class CreateElectricityProfileResult {
        @AuraEnabled public String profileId {get; set;}
        @AuraEnabled public String serviceTypes {get; set;}
    }
    
    // createSolarProfile
    
    public class CreateSolarProfileRequest {
        @AuraEnabled public String providerAccountId {get; set;}
        @AuraEnabled public String providerProfileId {get; set;}
        @AuraEnabled public String groupBy {get; set;}
        @AuraEnabled public String serviceTypes {get; set;}
        @AuraEnabled public Source source {get; set;}
        @AuraEnabled public CreateSolarProfileProperty properties {get; set;}
    }
    
    public class Source {
        @AuraEnabled public String sourceId {get; set;}
        @AuraEnabled public String sourceVersion {get; set;}
    }
    
    public class CreateSolarProfileProperty {
        @AuraEnabled public PropertyInput systemSize {get; set;}
        @AuraEnabled public PropertyInput azimuth {get; set;}
        @AuraEnabled public PropertyInput losses {get; set;}
        @AuraEnabled public PropertyInput inverterEfficiency {get; set;}
        @AuraEnabled public PropertyInput tilt {get; set;}
        @AuraEnabled public PropertyInput bifaciality {get; set;}
        @AuraEnabled public PropertyInput albedo {get; set;}
        @AuraEnabled public PropertyInput useWeatherFileAlbedo {get; set;}
        @AuraEnabled public PropertyInput soiling {get; set;}
    }
    
    public class CreateSolarProfileResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<CreateSolarProfileResult> results {get; set;}
    }
    
    public class CreateSolarProfileResult {
        @AuraEnabled public String providerProfileId {get; set;}
        @AuraEnabled public List<Measure> baselineMeasures {get; set;}
    }
    
    // createStorageProfile
    
    public class CreateStorageProfileRequest {
        @AuraEnabled public String providerAccountId;
        @AuraEnabled public String providerProfileId;
        @AuraEnabled public String fromDateTime;
        @AuraEnabled public Consumption consumption;
        @AuraEnabled public List<Solar> solar;
        @AuraEnabled public Storage storage;
    }
    
    public class Consumption {
        @AuraEnabled public String providerProfileId;
    }
    
    public class Solar {
        @AuraEnabled public String providerProfileId;
        @AuraEnabled public Decimal dataFactor;
    }
    
    public class Storage {
        @AuraEnabled public String mainTariffId;
        @AuraEnabled public DispatchStrategy dispatchStrategy;
        @AuraEnabled public Decimal batteryNameplatePower;
        @AuraEnabled public Decimal batteryNameplateCapacity;
        @AuraEnabled public Decimal batteryMinSoc;
        @AuraEnabled public Decimal batteryMaxSoc;
        @AuraEnabled public Decimal batteryInitialSoc;
        @AuraEnabled public Boolean batteryDcCoupled;
        @AuraEnabled public Decimal batteryAcToDcEfficiency;
        @AuraEnabled public Decimal batteryDcToAcEfficiency;
        @AuraEnabled public Decimal batteryInputEfficiency;
        @AuraEnabled public Decimal batteryDegradationCost;
        @AuraEnabled public Decimal solarDcToAcEfficiency;
        @AuraEnabled public Boolean allowBatteryToGrid;
        @AuraEnabled public Boolean allowGridToBattery;
        @AuraEnabled public Boolean allowSolarToGrid;
        @AuraEnabled public Boolean allowSolarToBattery;
        @AuraEnabled public List<PropertyInput> tariffPropertyInputs;
    }
    
    public class DispatchStrategy {
        @AuraEnabled public Boolean optimize;
    }
    
    public class CreateStorageProfileResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<CreateStorageProfileResult> results {get; set;}
    }
    
    public class CreateStorageProfileResult {
        @AuraEnabled public CreateStorageProfileUsageProfile usageProfile {get; set;}
    }
    
    public class CreateStorageProfileUsageProfile {
        @AuraEnabled public String providerProfileId {get; set;}
    }
    
    // getTypicalBaselines
    
    public class TypicalBaselineResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<TypicalBaselineResult> results {get; set;}
    }
    
    public class TypicalBaselineResult {
        @AuraEnabled public List<Measure> measures {get; set;}
    }
    
    public class Measure {
        @AuraEnabled public Integer i {get; set;}
        @AuraEnabled public Decimal v {get; set;}
    }
    
    // calculateCost
    
    /* public class CalculateCostRequest {
        @AuraEnabled public String fromDateTime {get; set;}
        @AuraEnabled public String toDateTime {get; set;}
        @AuraEnabled public String groupBy {get; set;}
        @AuraEnabled public Boolean autoBaseline {get; set;}
        @AuraEnabled public Boolean useIntelligentBaselining {get; set;}
        @AuraEnabled public List<PropertyInput> propertyInputs {get; set;}
    }
    
    public class CalculateCostResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<CalculateCostResult> results {get; set;}
    }
    
    public class CalculateCostResult {
        @AuraEnabled public CalculateCostSummary summary {get; set;}
        @AuraEnabled public List<CalculateCostItem> items {get; set;}
    }
    
    public class CalculateCostSummary {
        @AuraEnabled public Decimal totalCost {get; set;}
        @AuraEnabled public Decimal kWh {get; set;}
    }
    
    public class CalculateCostItem {
        @AuraEnabled public String rateGroupName {get; set;}
        @AuraEnabled public Decimal itemQuantity {get; set;}
        @AuraEnabled public Decimal cost {get; set;}
        @AuraEnabled public DateTime fromDateTime {get; set;}
        @AuraEnabled public DateTime toDateTime {get; set;}
    } */
    
    // getAnalysis
    
    public class AnalysisRequest {
        @AuraEnabled public String providerAccountId {get; set;}
        @AuraEnabled public String fromDateTime {get; set;}
        @AuraEnabled public Boolean autoBaseline {get; set;}
        @AuraEnabled public Boolean useIntelligentBaselining {get; set;}
        @AuraEnabled public String tariffEffectiveOn {get; set;}
        @AuraEnabled public List<PropertyInput> propertyInputs {get; set;}
        @AuraEnabled public List<RateInput> rateInputs {get; set;}
    }
    
    public class RateInput {
        @AuraEnabled public String scenarios {get; set;}
        @AuraEnabled public String chargeType {get; set;}
        @AuraEnabled public String masterTariffRateId {get; set;}
        @AuraEnabled public String tariffBookSequenceNumber {get; set;}
        @AuraEnabled public String tariffBookRateGroupName {get; set;}
        @AuraEnabled public String tariffBookRateName {get; set;}
        @AuraEnabled public String fromDateTime {get; set;}
        @AuraEnabled public String toDateTime {get; set;}
        @AuraEnabled public String chargePeriod {get; set;}
        @AuraEnabled public String transactionType {get; set;}
        @AuraEnabled public List<RateBand> rateBands {get; set;}
    }
    
    public class RateBand {
        @AuraEnabled public Decimal rateAmount {get; set;}
        @AuraEnabled public String tariffRateBandId {get; set;}
        @AuraEnabled public String tariffRateId {get; set;}
        @AuraEnabled public String rateSequenceNumber {get; set;}
        @AuraEnabled public Boolean hasConsumptionLimit {get; set;}
        @AuraEnabled public Boolean hasDemandLimit {get; set;}
        @AuraEnabled public Boolean hasPropertyLimit {get; set;}
        @AuraEnabled public String rateUnit {get; set;}
        @AuraEnabled public Boolean isCredit {get; set;}
        @AuraEnabled public String prevUpperLimit {get; set;}
    }
    
    public class AnalysisResponse {
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public List<AnalysisResult> results {get; set;}
    }
    
    public class AnalysisResult {
        @AuraEnabled public AnalysisSummary summary {get; set;}
    }
    
    public class AnalysisSummary {
        @AuraEnabled public Decimal lifetimeSolarCost {get; set;}
        @AuraEnabled public Decimal lifetimeWithoutCost {get; set;}
        @AuraEnabled public Decimal postTotalCost {get; set;}
        @AuraEnabled public Decimal preTotalCost {get; set;}
    }
}