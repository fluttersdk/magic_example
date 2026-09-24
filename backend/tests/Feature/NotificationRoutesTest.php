<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * The Flutter client ships with `notifications: true` in `lib/config/magic_starter.dart`,
 * so its notifications screen and bell poll these routes from the first sign-in. They
 * exist only while the backend enables the same feature; with it off, every poll is a 404.
 */
class NotificationRoutesTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_notification_list_answers_the_signed_in_user(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/v1/notifications')->assertOk();
    }

    public function test_a_database_notification_reaches_the_list(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $user->notify(new DatabaseOnlyNotification);

        $this->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonPath('data.0.data.title', 'Deploy finished');
        $this->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.count', 1);
    }

    public function test_the_unread_count_answers_the_signed_in_user(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/v1/notifications/unread-count')->assertOk();
    }

    public function test_the_notification_preferences_answer_the_signed_in_user(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/v1/notification-preferences')->assertOk();
    }

    public function test_the_notification_list_refuses_a_guest(): void
    {
        $this->getJson('/api/v1/notifications')->assertUnauthorized();
    }
}
