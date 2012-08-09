//
//  IAPHelper.m
//  GolfSwingMeter
//
//  Created by Liangjun Jiang on 7/20/12.
//  Copyright (c) 2012 ByPass Lane. All rights reserved.
//

#import "IAPHelper.h"

@implementation IAPHelper
@synthesize productIdentifier = _produtIdentifiers;
@synthesize products = _products;
@synthesize purchasedProducts = _purchasedProducts;
@synthesize request = _request;

- (void)requestProducts{
       
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:_produtIdentifiers];
    _request.delegate = self;
    [_request start];
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers
{
    if ((self = [super init])) {
        _produtIdentifiers = productIdentifiers;
    
        // Check for Previous Purchased products
        NSMutableSet *purchasedProducts = [NSMutableSet set];
        [_produtIdentifiers enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:obj];
            
            if (productPurchased) {
                [purchasedProducts addObject:obj];
                NSLog(@"purchased: %@",obj);
            }
            
            NSLog(@"not purchased: %@",obj);
        }];
    
        self.purchasedProducts = purchasedProducts;
    }
    
    return self;
}


- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    
    self.products = response.products;
    NSLog(@"server retured: %@",response.products);
    self.request = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductsLoadedNotification object:_products];
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"what's the error :%@",error.localizedDescription);
    
}

- (void)buyProductIdentifier:(NSString *)productIdentifier {
    NSLog(@"Buying :%@ ...", productIdentifier);
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

# pragma mark - delegate methods
- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    // Optional: Record the transaction on the server side...
}

- (void)provideContent: (NSString *)productIdentifier {
    NSLog(@"toggle flag for :%@", productIdentifier);
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_purchasedProducts addObject:productIdentifier];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    NSLog(@"Complete transaction");
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restore transaction");
    [self recordTransaction:transaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"Transaction error: %@",transaction.error.localizedDescription);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductPurchaseFailedNotification object:transaction];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    [transactions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        SKPaymentTransaction *transaction = (SKPaymentTransaction *)obj;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
        
    }];
}



@end