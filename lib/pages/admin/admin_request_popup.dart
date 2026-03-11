// ✅ FIX #5 & #14: This file has been removed.
//
// The AdminRequestPopup widget that lived here was a duplicate of _RequestPopup
// inside admin_request_page.dart. The two implementations had diverged — this
// one read raw Map data and was no longer imported anywhere. All approve /
// reject logic now lives exclusively in admin_request_page.dart (_RequestPopup).
//
// This file is kept as an empty placeholder to avoid breaking any git history
// references. It exports nothing and should not be imported.
